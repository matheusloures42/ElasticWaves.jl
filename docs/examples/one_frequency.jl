using ElasticWaves
using MultipleScattering
using Statistics
using Plots
using FFTW
using LinearAlgebra

#Try to Construct the force using a direct fourier transform of the fourier series. 

#=
(For 1 Roller )
The inverse problem solves exact for number_of_sensors= basis_order +2 for both cases for any frequency 
with prior method. it is still terrible without priors.
If we put less than that the tractions observed have the same shape but the amplitudes are not correct. However it recovers correctly 
the ratio of the amplitudes.
 (For 10 Rollers)
 with basis_order=10 and number_of_sensors=21=basis_length we can see the deltas but not as in the input.
=#

function δ(m,ω,ω_0)

    return (1/2pi)*sum( exp(im*n*(ω-ω_0) ) for n in -m:m   )
    
end


#Definining parameters of the problem

basis_order = 2;

numberofsensors = 4

basis_length = 2*basis_order + 1

#Friction coefficient

μ=0.5
#μ=1
#θs = LinRange(0, 2pi, basis_length + 1)[1:end-1]
θs = LinRange(0, 2pi, 500)[1:end-1] 
#θ2s = LinRange(0, 2pi, 4*basis_length + 1)[1:end-1]
θ2s = LinRange(0, 2pi, 2000)[1:end-1] 
θs_inv = LinRange(0, 2pi, numberofsensors + 1)[1:end-1]

#Properties of the bearing

steel = Elastic(2; ρ = 7800.0, cp = 5000.0, cs = 3500.0)
bearing = RollerBearing(medium=steel, inner_radius=1.0, outer_radius = 2.0, number_of_rollers=1.0)

Z=bearing.number_of_rollers

#Angular velocity of the bearings

Ω=10

#Desired frequency
n=basis_order

ω=n*Z*Ω

number_of_ωs=101

ωs=LinRange(0.8*ω,1.2*ω,number_of_ωs)

#plot ωs arround desired frequency
plot(ωs,real.(δ.(100,ωs,ω)))


# ωs = LinRange(0.8*ω,1.2*ω,number_of_ωs) |> transpose |>collect

i = Int((number_of_ωs-1)/2 +1)

ωs[i]

ωs0 = repeat(ωs |> transpose, outer= length(θs))

n_order = basis_order

#Fp= Z/(2πΩ) ∑_n F( exp(iZn(Ωt-θ) ))= (Z/Ω) ∑_n exp(-iZn θ) δ(ω-nZΩ). #Need to test it to Fp=∑ cn e^(iω_nt) where ω_n=nZΩ and cn=e^(-iZn Ω)

Fp = [
    (Z/(2pi*Ω)) .* sum(
        exp.(-im.*n.*Z.*(θs)).*δ.(100,ωs[i],ω) 
    for n in -n_order:n_order) 
for i in 1:length(ωs)] .|> real


plot(θs, Fp[i])

Fs = μ.*Fp

#Boundary conditions for the forward and inverse problems

bc1_forward = TractionBoundary(inner=true)
bc2_forward = TractionBoundary(outer=true)

bc1_inverse = DisplacementBoundary(outer=true)
bc2_inverse = TractionBoundary(outer=true)

#FORWARD PROBLEM

fouter = 0 .* exp.(-20.0 .* (θs .- pi).^2) + θs .* 0im


bd1_forward = [BoundaryData(bc1_forward, θs=θs, fields=hcat(Fp[i],Fs[i])) for i in 1:length(ωs)]

bd1_forward_modes = fields_to_fouriermodes.(bd1_forward, basis_order)

bd1_forward_fields = fouriermodes_to_fields.(bd1_forward_modes)

bd2_forward = BoundaryData(bc2_forward, θs=θs, fields=hcat(fouter,fouter))

#bd2_forward = fields_to_fouriermodes(bd2_forward, basis_order)


plot(θs, real.(Fp[i]))
plot!(θs, real.(Fs[i]))


sim = BearingSimulation(ωs[i], bearing, bd1_forward[i], bd2_forward; basis_order = basis_order)

wave = ElasticWave(sim)


# res = field(wave, bearing, TractionType(); res = 70)

# scale the potential to match the units of stress

scale = steel.ρ * ωs[i]^2

wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(wave.potentials[1].wavespeed, wave.potentials[1].wavenumber, scale .* wave.potentials[1].coefficients)

res = field(potential, bearing; res = 120)

# plot the radial traction
plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))


#INVERSE WITHOUT PRIOR

#x_outer are the coordinates where our sensors are
x_outer = [radial_to_cartesian_coordinates([bearing.outer_radius,θ]) for θ in θs_inv ]

#x2_inner are the cooordinates that we will calculate the forces that the fields of our solutions generates
x2_inner = [
    radial_to_cartesian_coordinates([bearing.inner_radius, θ])
for θ in θ2s]

x2_outer = [
    radial_to_cartesian_coordinates([bearing.outer_radius, θ])
for θ in θ2s]


#calculate displacement generated by the forward problem

displacement_outer = [displacement(wave,x) for x in x_outer];
displacement_outer = hcat(displacement_outer...) |> transpose |> collect;

traction_outer = [traction(wave,x) for x in x_outer]
traction_outer = hcat(traction_outer...) |> transpose |> collect;

#Generate displacement for the inverse problem

bd1_inverse = BoundaryData(
    bc1_inverse;
    θs = θs_inv,
    fields = displacement_outer
)

bd1_inverse_modes = fields_to_fouriermodes(bd1_inverse, basis_order)
bd1_inverse_fields = fouriermodes_to_fields(bd1_inverse_modes)
norm(bd1_inverse.fields - bd1_inverse_fields.fields)

# traction_outer_forward= traction_outer_inverse

bd2_inverse= BoundaryData(
    bc2_inverse;
    θs = θs_inv,
    fields = traction_outer
)

bd2_inverse_modes=fields_to_fouriermodes(bd2_inverse, basis_order)
bd2_inverse_fields=fouriermodes_to_fields(bd2_inverse_modes)
norm(bd2_inverse.fields-bd2_inverse_fields.fields)

#bd2_inverse=fields_to_fouriermodes(bd2_inverse, basis_order)

inverse_sim = BearingSimulation(ωs[i], bearing, bd1_inverse, bd2_inverse, basis_order=basis_order)    
 res = field(wave, bearing, TractionType(); res = 70)

inv_wave=ElasticWave(inverse_sim)

#Calculate and compute for the inverse problem without prior.

traction_for_ω= [traction(wave,x) for x in x2_inner]
traction_for_ω = hcat(traction_for_ω...) |> transpose |> collect

traction_inv_ω = [traction(inv_wave,x) for x in x2_inner];
traction_inv_ω = hcat(traction_inv_ω...) |> transpose |> collect

plot(θs, real.(Fp[i]), linewidth = 2)
plot!(θ2s,real.(traction_for_ω[:,1]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,1]), linestyle = :dash, linewidth = 2)

plot(θs, real.(Fs[i]), linewidth = 2)
plot!(θ2s,real.(traction_for_ω[:,2]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,2]), linestyle = :dash, linewidth = 2)



scale = steel.ρ * ωs[i]^2

inv_wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(inv_wave.potentials[1].wavespeed, 
inv_wave.potentials[1].wavenumber, scale .* inv_wave.potentials[1].coefficients)

res = field(potential, bearing; res = 120)

plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))


#PRIOR METHOD

#Define prior without giving the amplitudes

Fp1= real.([(Z/(2pi*Ω)).*sum(exp.(-im.*n.*Z.*(θs)).*δ.(100,ωs[i],ω) for n in -n_order:n_order ) for i in 1:length(ωs)])
Fs1 =  Fp1


#=
Fp1=zeros(Complex{Float64}, number_of_ωs , length(θs))
Fs1=zeros(Complex{Float64}, number_of_ωs , length(θs))

for i in 1:length(θs)
    Fp1[:,i] = rfft(fp1[:,i])
    Fs1[:,i] = rfft(fs1[:,i])
    
end
=#



f0=0 .*Fp1

#Creating the basis for each frequency

bd1=[ BoundaryData(bc1_forward, θs=θs, fields=hcat(Fp1[i],f0[i])) for i in 1:length(ωs) ]
bd2=[ BoundaryData(bc1_forward, θs=θs, fields=hcat(f0[i],Fs1[i])) for i in 1:length(ωs) ]

#bd1= fields_to_fouriermodes.(bd1, basis_order)
#bd2= fields_to_fouriermodes.(bd2, basis_order)
#plot(θs,abs.(Fp1[50,:]))


boundarybasis= [ BoundaryBasis( [ bd1[i] , bd2[i]] ) for i in 1:length(ωs)  ]

#Generate boundary data

bd1_inverse = BoundaryData(
    bc1_inverse;
    θs = θs_inv,
    fields = displacement_outer
)


#bd1_inverse=fields_to_fouriermodes(bd1_inverse, basis_order)


bd2_inverse= BoundaryData(
    bc2_inverse;
    θs = θs_inv,
    fields = traction_outer
)

#bd2_inverse=fields_to_fouriermodes(bd2_inverse, basis_order)

inverse_sim = BearingSimulation(ωs[i], bearing, bd1_inverse, bd2_inverse, boundarybasis1=boundarybasis[i],basis_order=basis_order)    
# res = field(wave, bearing, TractionType(); res = 70)

inv_wave=ElasticWave(inverse_sim)

#solve with prior.

#calculate_predicted_tractions

traction_inv_ω = [traction(inv_wave,x) for x in x2_inner];
traction_inv_ω = hcat(traction_inv_ω...) |> transpose |> collect

plot(θs, real.(Fp[i]), linewidth = 2)
plot!(θ2s,real.(traction_for_ω[:,1]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,1]), linestyle = :dash, linewidth = 2)

plot(θs, real.(Fs[i]), linewidth = 2)
plot!(θ2s,real.(traction_for_ω[:,2]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,2]), linestyle = :dash, linewidth = 2)

maximum(real.(traction_inv_ω[:,2]))/maximum(real.(traction_inv_ω[:,1]))

#plot the fields

scale = steel.ρ * ωs[i]^2


inv_wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(inv_wave.potentials[1].wavespeed, 
inv_wave.potentials[1].wavenumber, scale .* inv_wave.potentials[1].coefficients)

res = field(potential, bearing; res = 120)

plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))
