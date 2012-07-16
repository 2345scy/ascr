TOP_OF_MAIN_SECTION
  arrmblsize=1500000;

DATA_SECTION
  init_int n
  init_int ntraps
  init_int nmask
  init_number A
  init_matrix capt(1,n,1,ntraps)
  init_matrix dist(1,ntraps,1,nmask)

PARAMETER_SECTION
  init_number logitg0
  init_number logsigma
  init_number logD
  random_effects_vector xhc(1,n)
  random_effects_vector yhc(1,n)
  objective_function_value nll

PROCEDURE_SECTION
  // Setting up variables
  int i,j;
  dvariable g0,sigma,D,p,lambda,L1,L2,L3,dist;
  dvar_matrix p1(1,ntraps,1,nmask);
  dvar_matrix p2(1,ntraps,1,nmask);
  dvar_matrix logp1(1,ntraps,1,nmask);
  dvar_matrix logp2(1,ntraps,1,nmask); 
  dvar_vector pm(1,nmask);
  dvar_vector wi1(1,ntraps);
  dvar_vector wi2(1,ntraps);
  // Setting up parameter values on their proper scales
  g0=mfexp(logitg0)/(1+mfexp(logitg0));
  sigma=exp(logsigma);
  D=exp(logD);
  // Probabilities of caputure at each location for each trap
  p1=g0*mfexp(-square(dist)/(2*square(sigma)));
  p2=1-p1;
  logp1=log(p1);
  logp2=log(p2);
  // Probability of detection at any trap for each location
  // Required for poisson bit
  for(i=1; i<=nmask; i++){
    p=1;
    for(j=1; j<=ntraps; j++){
      p*=p2(j)(i);
    }
    pm(i)=1-p;
  }
  L1=0;
  // Probability of capture histories for each animal
  for(i=1; i<=n; i++){
    wi1=capt(i)(1,ntraps);
    wi2=1-wi1;
    L1+=log(D*sum(mfexp(wi1*logp1+wi2*logp2)));
  }
  // Putting log-likelihood together
  lambda=A*D*sum(pm);
  L2=-n*log(D*sum(pm));
  L3=log_density_poisson(n,lambda);
  nll=-(L1+L2+L3);
   
REPORT_SECTION