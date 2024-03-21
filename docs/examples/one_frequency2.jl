using ElasticWaves
using MultipleScattering
using Statistics
using Plots
using FFTW
using LinearAlgebra

#This code do the same of the Zrollers_contact but we extract only one frequency.

basis_order = 11;
numberofsensors = 2
basis_length = 2*basis_order + 1

#Friction coefficient

μ=0.5
#μ=1
θs = LinRange(0, 2pi, 20*basis_length + 2)[1:end-1]
#θs = LinRange(0, 2pi, 401)[1:end-1] 
#θ2s = LinRange(0, 2pi, 4*basis_length + 1)[1:end-1]
θ2s = LinRange(0, 2pi, 2000)[1:end-1] 
θs_inv = LinRange(0, 2pi, numberofsensors + 1)[1:end-1]


#Friction coefficient


#Properties of the bearing

steel = Elastic(2; ρ = 7800.0, cp = 5000.0, cs = 3500.0)
bearing = RollerBearing(medium=steel, inner_radius=1.0, outer_radius = 2.0, number_of_rollers=11)

Z=bearing.number_of_rollers

#Angular velocity of the bearings

Ω=1000.0

#frequencies
n_order=basis_order
ωs=[n*Z*Ω for n in 0:n_order] 

size=2*n_order*Z+1 |>Int

fourier_coef_p=zeros(size)

for n in -n_order:n_order
    fourier_coef_p[Int(n_order*Z)+1+Int(n*Z)]=Z/2pi

end

fourier_coef_s=μ.*fourier_coef_p 

i=10

bc1_forward = TractionBoundary(inner=true)
bc2_forward = TractionBoundary(outer=true)

bc1_inverse = DisplacementBoundary(outer=true)
bc2_inverse = TractionBoundary(outer=true)

fouter= 0*fourier_coef_p

bd1_forward =  BoundaryData(bc1_forward, θs=θs, coefficients = hcat(fourier_coef_p,fourier_coef_s)) 
bd2_forward = BoundaryData(bc2_forward,θs=θs, coefficients = hcat(fouter,fouter))

modal_method=ModalMethod(tol=1e-6,only_stable_modes=true)

sim = BearingSimulation(ωs[i], bearing, bd1_forward, bd2_forward; method=modal_method)



wave = ElasticWave(sim)



#x_outer are the coordinates where our sensors are
x_outer=[radial_to_cartesian_coordinates([bearing.outer_radius,θ]) for θ in θs_inv ]

#x2_inner are the cooordinates that we will calculate the forces that the fields of our solutions generates
x2_inner = [
    radial_to_cartesian_coordinates([bearing.inner_radius, θ])
for θ in θ2s]


x2_outer = [
    radial_to_cartesian_coordinates([bearing.outer_radius, θ])
for θ in θ2s]




traction_for_ω= [traction(wave,x) for x in x2_inner]
traction_for_ω = hcat(traction_for_ω...) |> transpose |> collect

plot(θ2s,real.(traction_for_ω[:,1]))


# res = field(wave, bearing, TractionType(); res = 70)

# scale the potential to match the units of stress

scale = steel.ρ * ωs[i]^2

wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(wave.potentials[1].wavespeed, wave.potentials[1].wavenumber, scale .* wave.potentials[1].coefficients, wave.potentials[1].modes)

res = field(potential, bearing; res = 120)

# plot the radial traction
plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))



#INVERSE WITHOUT PRIOR


#calculate displacement generated by the forward problem

# 
displacement_outer = [displacement(wave,x) for x in x_outer];
displacement_outer = hcat(displacement_outer...) |> transpose |> collect;


traction_outer= [traction(wave,x) for x in x_outer]
traction_outer = hcat(traction_outer...) |> transpose |> collect;


#Generate displacement for the inverse problem

bd1_inverse = BoundaryData(
    bc1_inverse;
    θs = θs_inv,
    fields = displacement_outer
)

bd1_inverse_modes=fields_to_fouriermodes(bd1_inverse)
bd1_inverse_fields=fouriermodes_to_fields(bd1_inverse_modes)
norm(bd1_inverse.fields-bd1_inverse_fields.fields)

# traction_outer_forward= traction_outer_inverse

bd2_inverse= BoundaryData(
    bc2_inverse;
    θs = θs_inv,
    fields = traction_outer
)

#bd2_inverse_modes=fields_to_fouriermodes(bd2_inverse, basis_order)
#bd2_inverse_fields=fouriermodes_to_fields(bd2_inverse_modes)
#norm(bd2_inverse.fields-bd2_inverse_fields.fields)

#bd2_inverse=fields_to_fouriermodes(bd2_inverse, basis_order)

modal_method_inv=ModalMethod(tol=1e-6,only_stable_modes=false)

inverse_sim = BearingSimulation(ωs[i], bearing, bd1_inverse, bd2_inverse, method=modal_method_inv)    

inv_wave=ElasticWave(inverse_sim)

#Calculate and compute for the inverse problem without prior.

traction_for_ω= [traction(wave,x) for x in x2_inner]
traction_for_ω = hcat(traction_for_ω...) |> transpose |> collect

traction_inv_ω = [traction(inv_wave,x) for x in x2_inner];
traction_inv_ω = hcat(traction_inv_ω...) |> transpose |> collect


plot(θ2s,real.(traction_for_ω[:,1]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,1]), linestyle = :dash, linewidth = 2)


plot(θ2s,real.(traction_for_ω[:,2]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,2]), linestyle = :dash, linewidth = 2)



scale = steel.ρ * ωs[i]^2

inv_wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(inv_wave.potentials[1].wavespeed, 
inv_wave.potentials[1].wavenumber, scale .* inv_wave.potentials[1].coefficients, inv_wave.potentials[1].modes)

res = field(potential, bearing; res = 120)

plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))

#PRIOR METHOD

n=i

Fp=fourier_coef_p
Fs=fourier_coef_p 




f0=0.0*Fp




bd1= BoundaryData(bc1_forward, θs=θs, coefficients = hcat(Fp,f0)) 
bd2= BoundaryData(bc1_forward, θs=θs, coefficients = hcat(f0,Fs)) 

bd3= BoundaryData(bc2_forward, θs=θs, coefficients = hcat(f0,f0)) 
bd4= BoundaryData(bc2_forward, θs=θs, coefficients = hcat(f0,f0)) 



boundarybasis=  BoundaryBasis( [ bd1 , bd2] )   
boundarybasis2=BoundaryBasis([bd3,bd4])

#Generate boundary data

bd1_inverse = BoundaryData(
    bc1_inverse;
    θs = θs_inv,
    fields = displacement_outer
)

#bd1_inverse=fields_to_fouriermodes(bd1_inverse,n_order*Z)


#bd1_inverse=fields_to_fouriermodes(bd1_inverse, basis_order)


bd2_inverse= BoundaryData(
    bc2_inverse;
    θs = θs_inv,
    fields = traction_outer
)

#bd2_inverse=fields_to_fouriermodes(bd2_inverse, sim.basis_order)

prior_method=PriorMethod(tol=modal_method.tol, modal_method=modal_method)

inverse_sim = BearingSimulation(ωs[i], bearing, bd1_inverse, bd2_inverse
, boundarybasis1=boundarybasis,boundarybasis2=boundarybasis2 
, method=prior_method,nondimensionalise=true)    
# res = field(wave, bearing, TractionType(); res = 70)

inv_wave=ElasticWave(inverse_sim)

#solve with prior.

#calculate_predicted_tractions

traction_inv_ω = [traction(inv_wave,x) for x in x2_inner];
traction_inv_ω = hcat(traction_inv_ω...) |> transpose |> collect


plot(θ2s,real.(traction_for_ω[:,1]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,1]), linestyle = :dash, linewidth = 2)

plot(θ2s,real.(traction_for_ω[:,2]), linestyle = :dash, linewidth = 2)
plot!(θ2s,real.(traction_inv_ω[:,2]), linestyle = :dash, linewidth = 2)

maximum(real.(traction_inv_ω[:,2]))/maximum(real.(traction_inv_ω[:,1]))

#plot the fields

scale = steel.ρ * ωs[i]^2


inv_wave.potentials[1].coefficients

potential = HelmholtzPotential{2}(inv_wave.potentials[1].wavespeed, 
inv_wave.potentials[1].wavenumber, scale .* inv_wave.potentials[1].coefficients, inv_wave.potentials[1].modes)

res = field(potential, bearing; res = 120)

plot(res,ωs[i]; seriestype=:heatmap, field_apply = f -> real(f[1]))
plot!(Circle(bearing.inner_radius))
plot!(Circle(bearing.outer_radius))