(* ::Package:: *)

(* ::Subsection:: *)
(*How to solve the unstable boundary condition system*)
(**)


(* ::Input:: *)
(*ClearAll[x,B,a,c,b,f,M]*)
(*(*The smallest example of a similar unstable system is*)*)
(**)
(*M  =\!\(\**)
(*TagBox[*)
(*RowBox[{"(", GridBox[{*)
(*{*)
(*RowBox[{*)
(*SubscriptBox["J", "n"], "[", *)
(*RowBox[{"a1", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}], *)
(*RowBox[{*)
(*SubscriptBox["H", "n"], "[", *)
(*RowBox[{"a1", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]},*)
(*{*)
(*RowBox[{"-", *)
(*RowBox[{*)
(*SubscriptBox["J", "n"], "[", *)
(*RowBox[{"a2", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]}], *)
(*RowBox[{"-", *)
(*RowBox[{*)
(*SubscriptBox["H", "n"], "[", *)
(*RowBox[{"a2", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]}]}*)
(*},*)
(*GridBoxAlignment->{"Columns" -> {{Center}}, "Rows" -> {{Baseline}}},*)
(*GridBoxSpacings->{"Columns" -> {Offset[0.27999999999999997`], {Offset[0.7]}, Offset[0.27999999999999997`]}, "Rows" -> {Offset[0.2], {Offset[0.4]}, Offset[0.2]}}], ")"}],*)
(*Function[BoxForm`e$, MatrixForm[BoxForm`e$]]]\);*)
(*B= {0,fo[n] Subscript[J, n][ko a[1]]};*)
(*B= {-fo[n],fo[n] };*)
(**)
(*subN = {a2->2.`,a1->1.5`,ko->0.0001`,k[1]->2.`,Subscript[J, n][ko a[1]]->1.`,fo[n]->1,Subscript[H, n_][x_]->HankelH1[n,x],Subscript[J, n_][x_]->BesselJ[n,x],Derivative[1][Subscript[H, n_]][x_]->1/2 (HankelH1[-1+n,x]-HankelH1[1+n,x]),Derivative[1][Subscript[J, n_]][x_]->1/2 (BesselJ[-1+n,x]-BesselJ[1+n,x])};*)
(*(*subN = subN/.BesselJ ->HankelH2;*)*)
(**)


(* ::Input:: *)
(*dn = 3;*)
(*ns = Range[0,35,dn];*)
(**)
(*NM = M//.subN;*)
(*NB = B//.subN;*)
(*(*NB = NM.xo*)*)
(*{Abs@Det[NM/.n->#],SingularValueList[NM/.n->#]}&/@ns*)


(* ::Input:: *)
(*(*which has the well posed solution*)*)
(*eqs = M . {a[n],c[n]} -NB;*)
(*\[Epsilon] = 10^-14;*)
(*subsol=Solve[eqs==RandomReal[\[Epsilon],2] +RandomReal[\[Epsilon],2] I,{a[n],c[n]}]//Simplify//Flatten;*)
(*subsol2=Solve[eqs==RandomReal[\[Epsilon],2] +RandomReal[\[Epsilon],2] I,{a[n],c[n]}]//Simplify//Flatten;*)
(**)
(*(*test the solution*)*)
(*subNsols= (subsol//.subN//Flatten)/.n->#&/@ns ;*)
(*subNsols2= (subsol2//.subN//Flatten)/.n->#&/@ns ;*)
(**)
(*sols = Transpose[#/.Rule-> List][[2]]&/@subNsols;*)
(*sols2 = Transpose[#/.Rule-> List][[2]]&/@subNsols2;*)
(**)
(*diffsols = sols-sols2;*)
(*Norm/@diffsols*)
(**)
(**)
(*#[[1]]&/@diffsols;*)
(*Abs[% *( BesselJ[#,a1 k[1]//.subN]&/@ns)]*)
(**)
(**)
(*#[[2]]&/@diffsols;*)
(*Abs[% *( HankelH1[#,a1 k[1]//.subN]&/@ns)]*)


(* ::Input:: *)
(*invM = Inverse[M];*)
(*Nxs = Table[*)
(**)
(*invNM =invM//.subN/.n->n1;*)
(*sol =invNM . (NB +RandomReal[\[Epsilon],2] +RandomReal[\[Epsilon],2] I//.subN/.n->n1) *)
(*,{n1,ns[[1]],ns//Last,dn}];*)
(**)


(* ::Input:: *)
(*sublinsols =Flatten[ Thread[({a[n],c[n]}/.subN/.n->#)->LinearSolve[NM/.n->#,NB+ RandomReal[{-10^-15,10^-15},2]/.n->#]]&/@ns]//Quiet;*)
(**)
(**)


(* ::Subsubsection:: *)
(*Try to condition Matrix *)


(* ::Input:: *)
(*(*The smallest example of a similar unstable system is*)*)
(**)
(*M  =\!\(\**)
(*TagBox[*)
(*RowBox[{"(", GridBox[{*)
(*{*)
(*RowBox[{*)
(*SubscriptBox["J", "n"], "[", *)
(*RowBox[{"a1", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}], *)
(*RowBox[{*)
(*SubscriptBox["H", "n"], "[", *)
(*RowBox[{"a1", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]},*)
(*{*)
(*RowBox[{"-", *)
(*RowBox[{*)
(*SubscriptBox["J", "n"], "[", *)
(*RowBox[{"a2", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]}], *)
(*RowBox[{"-", *)
(*RowBox[{*)
(*SubscriptBox["H", "n"], "[", *)
(*RowBox[{"a2", " ", *)
(*RowBox[{"k", "[", "1", "]"}]}], "]"}]}]}*)
(*},*)
(*GridBoxAlignment->{"Columns" -> {{Center}}, "Rows" -> {{Baseline}}},*)
(*GridBoxSpacings->{"Columns" -> {Offset[0.27999999999999997`], {Offset[0.7]}, Offset[0.27999999999999997`]}, "Rows" -> {Offset[0.2], {Offset[0.4]}, Offset[0.2]}}], ")"}],*)
(*Function[BoxForm`e$, MatrixForm[BoxForm`e$]]]\);*)
(**)
(*B= {0,fo[n] Subscript[J, n][ko a[1]]};*)
(*B= {-fo[n],fo[n] };*)
(**)
(*subN = {a2->2.`,a1->1.5`,ko->0.0001`,k[1]->2.`,Subscript[J, n][ko a[1]]->1.`,fo[n]->1,Subscript[H, n_][x_]->HankelH1[n,x],Subscript[J, n_][x_]->BesselJ[n,x],Derivative[1][Subscript[H, n_]][x_]->1/2 (HankelH1[-1+n,x]-HankelH1[1+n,x]),Derivative[1][Subscript[J, n_]][x_]->1/2 (BesselJ[-1+n,x]-BesselJ[1+n,x])};*)
(*(*subN = subN/.BesselJ ->HankelH2;*)*)
(**)


(* ::Input:: *)
(*dn = 7;*)
(*ns = Range[1,75,dn];*)
(**)
(*NM = M//.subN;*)
(*NB = B//.subN;*)
(*(*NB = NM.xo*)*)
(**)
(*(*Use the following to condition matrix*)*)
(*S = DiagonalMatrix[1/{Mean@Abs@NM[[All,1]],Mean@Abs@NM[[All,2]]}];*)
(**)
(*{Abs@Det[NM . S/.n->#],SingularValueList[NM . S/.n->#]}&/@ns*)


(* ::Input:: *)
(*(*Test the solutions*)*)
(*eqs = NM . S . {a[n],c[n]} -NB;*)
(*\[Epsilon] = 10^-14;*)
(*subsol=Solve[eqs==RandomReal[\[Epsilon],2] +RandomReal[\[Epsilon],2] I,{a[n],c[n]}]//Simplify//Flatten;*)
(*subsol2=Solve[eqs==RandomReal[\[Epsilon],2] +RandomReal[\[Epsilon],2] I,{a[n],c[n]}]//Simplify//Flatten;*)
(**)


(* ::Input:: *)
(*(*test the solution*)*)
(*Nsols=S . Transpose[subsol//.subN/.Rule-> List][[2]]/.n->#&/@ns ;*)
(*Nsols2=S . Transpose[subsol2//.subN/.Rule-> List][[2]]/.n->#&/@ns ;*)
(**)
(*(*relative error is small and of the order of \[Epsilon] !!*)*)
(*(Norm/@(Nsols-Nsols2)) /(Norm/@(Nsols))*)


(* ::Input:: *)
(*(*final check that we did indeed solve the original equation*)*)
(*Norm[(NM/.n->ns[[#]]) . Nsols[[#]]-NB]/Norm[NB]&/@Range@Length@ns*)


(* ::Input:: *)
(*diffsols = Nsols-Nsols2;*)
(*Norm/@diffsols*)
(**)
(*#[[1]]&/@diffsols*)
(**)
(*#[[2]]&/@diffsols*)
(**)


(* ::Subsection:: *)
(*4x4 matrix*)


(* ::Input:: *)
(*ClearAll[b,a,c,b,d,x];*)
(*(*The smallest example of a similar unstable system is*)*)
(*M = {*)
(*	{Subscript[J, n][a1 k[1]], Subscript[H, n][a1 k[1]],Subscript[J, n][a1 k[2]],Subscript[H, n][a1 k[2]]},*)
(*{Derivative[1][Subscript[J, n]][a1 k[1]], Derivative[1][Subscript[H, n]][a1 k[1]],Derivative[1][Subscript[J, n]][a1 k[2]],Derivative[1][Subscript[H, n]][a1 k[2]]},*)
(*	{Subscript[J, n][a2 k[1]], Subscript[H, n][a2 k[1]],Subscript[J, n][a2 k[2]],Subscript[H, n][a2 k[2]]},*)
(*         {Derivative[1][Subscript[J, n]][a2 k[1]], Derivative[1][Subscript[H, n]][a2 k[1]],Derivative[1][Subscript[J, n]][a2 k[2]],Derivative[1][Subscript[H, n]][a2 k[2]]}*)
(*};*)
(**)
(*B = {0,fo[n],0, fo[n]};*)
(**)
(*subN = {a2->2.0,a1->1.5,ko-> 0.1,k[1] -> 2.0,k[2] -> 3.2,Subscript[J, n][ko a[1]]->1.0,fo[n]->1, Subscript[H, n_][x_] ->HankelH1[n,x], Subscript[J, n_][x_] ->BesselJ[n,x], Derivative[1][Subscript[H, n_]][x_] ->D[HankelH1[n,x],x],Derivative[1][Subscript[J, n_]][x_] ->D[BesselJ[n,x],x]};*)
(**)


(* ::Input:: *)
(*dn = 7;*)
(*ns = Range[1,75,dn];*)
(**)
(*NM = M//.subN;*)
(*NB = B//.subN;*)
(**)
(*(*Use the following to condition matrix*)*)
(*S = DiagonalMatrix[Table[1/Mean@Abs@NM[[All,j]],{j,1,Length@B}]];*)


(* ::Input:: *)
(*{Abs@Det[NM . S/.n->#],SingularValueList[NM . S/.n->#]}&/@ns*)


(* ::Input:: *)
(*(*Solve without conditioning*)*)
(*vars =  Array[a,Length@B];*)
(*eqs = NM . vars-NB;*)
(*\[Epsilon] = 10^-14;*)
(*error:= RandomReal[\[Epsilon],Length@B] +RandomReal[\[Epsilon],Length@B] I*)
(*Nsols= Quiet@LinearSolve[NM/.n->#,NB+error/.n->#]&/@ns ;*)
(*Nsols2= Quiet@LinearSolve[NM/.n->#,NB+error/.n->#]&/@ns ;*)
(**)
(*(* Finds a good solution despite conditioning problems*)*)
(*(Norm/@(Nsols-Nsols2)) /(Norm/@(Nsols))*)


(* ::Input:: *)
(*vars =  Array[a,Length@B];*)
(*eqs = NM . S . vars-NB;*)
(*\[Epsilon] = 10^-14;*)
(**)
(*Nsols=(S/.n->#) . LinearSolve[NM . S/.n->#,NB+error/.n->#]&/@ns ;*)
(*Nsols2= (S/.n->#) . LinearSolve[NM . S/.n->#,NB+error/.n->#]&/@ns ;*)
(**)
(**)


(* ::Input:: *)
(*(*relative error is still small and of the order of \[Epsilon] !!*)*)
(*(Norm/@(Nsols-Nsols2)) /(Norm/@(Nsols))*)
(**)


(* ::Input:: *)
(*ClearAll[\[Psi]o,\[Psi],J,H]*)
(*\[Psi]o = fo[n] Subscript[J, n][ko r];*)
(*\[Psi][s] = Ao[n]Subscript[H, n][ko r];*)
(*\[Psi][1] = f[1,n] Subscript[J, n][k[1] r] + A[1,n]Subscript[H, n][k[1] r];*)
(*eqs = {\[Psi][1]  /.r-> a[0], \[Psi][s] + \[Psi]o  - \[Psi][1]/.r-> a[1],D[\[Psi][1],r]/\[Rho][1]  - D[\[Psi][s] + \[Psi]o ,r]/\[Rho]o/.r-> a[1]};*)
(**)
(*subsol = Solve[Thread[eqs==0],{Ao[n],f[1,n],A[1,n]}]  //Simplify;*)


(* ::Input:: *)
(*subN = {a[1]->2.0,a[0]->1.5,\[Rho]o->0.00001,\[Rho][1]->2.0,ko-> 0.0001,k[1] -> 2.0,Subscript[J, n][ko a[1]]->1.0,fo[n]->1, Subscript[H, n_][x_] ->HankelH1[n,x], Subscript[J, n_][x_] ->BesselJ[n,x], Derivative[1][Subscript[H, n_]][x_] ->D[HankelH1[n,x],x],Derivative[1][Subscript[J, n_]][x_] ->D[BesselJ[n,x],x]};*)
(*subsol//.subN//Flatten;*)


(* ::Input:: *)
(*%/.n->#&/@Range[1,20,3]*)
(**)


(* ::Input:: *)
(*(*Capsule with given forcing on boundary*)*)
(*ClearAll[\[Psi]o,\[Psi],J,H]*)
(*\[Psi]o = fo[n] Subscript[J, n][ko r];*)
(*\[Psi][1] = f[1,n] Subscript[J, n][k[1] r] + A[1,n]Subscript[H, n][k[1] r];*)
(*eqs = {\[Psi][1]  /.r-> a[0],  \[Psi]o  - \[Psi][1]/.r-> a[1]};*)
(*subsol = Solve[Thread[eqs==0],{f[1,n],A[1,n]}] /.{\[Rho]o -> qo ko,\[Rho][1] -> q[1] k[1],\[Rho][0] -> q[0] k[0]} //Simplify*)
(**)
(**)


(* ::Input:: *)
(*vars = {f[1,n],A[1,n]};*)
(*M = Coefficient[eqs,#]&/@vars;*)
(*M = Transpose@M;*)
(*b =  eqs - M . vars //Simplify;*)
(*M//MatrixForm*)


(* ::Input:: *)
(*subN = {a[1]->2.0,a[0]->1.5,k[1] -> 2.0,Subscript[J, n][ko a[1]]->1.0,fo[n]->1, Subscript[H, n_][x_] ->HankelH1[n,x], Subscript[J, n_][x_] ->BesselJ[n,x]};*)
(*ns = Range[1,40,3];*)
(*subsol//.subN//Flatten;*)
(*subNsol=Flatten[%/.n->#&/@ns];*)
(**)
(*eqs//.subN/.n->#&/@ns;*)
(*Norm/@(%/.subNsol)*)


(* ::Input:: *)
(*{Abs@f[1,n]Abs@BesselJ[n,a[1] k[1]],Abs@A[1,n]Abs@HankelH1[n,a[1] k[1]]}//.subN//Flatten;*)
(*%/.n->#&/@ns;*)
(*%/.Flatten@subNsol*)
(**)
