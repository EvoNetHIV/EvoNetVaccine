#' @export
viral_update_cd4_daily <- function(dat,at)
{  
  
  #Description:
  # Shifts CD4 value of infectees to next category if time in current category 
  # has expired, waiting time per CD4 category is either based on exponential distributions 
  # based on Pickles et al. data. or raw waiting times reported from their data (param$cd4_exp_flag=0/1)
  # otherwise cd4 value remains same
  #Input: dat$pop$CD4_TimeToAIDS_exp_cat1
  #dat$pop$CD4_time_cat2
  #dat$pop$CD4_time_cat3
  #dat$pop$CD4_time_cat4
  #dat$pop$CD4_time
  #dat$param$CD4_lookup
  #Output: dat$pop$CD4, CD4_time_death
  
  
  #ask john about aim3
  if(dat$param$VL_Function=="aim3"){
    # Aim 3 code allows virus to rebound due to drug resistance.  For aim 3 code, don't assume that treated
    # patients wont progress (i.e., don't restrict the list of infectees to those who aren't treated)
    # Note: It would probably be harmless to apply this to aim 2 code as well, but I am restricting this change
    # to the aim 3 code for the moment out of an abundance of caution
    infectees <- which(dat$pop$CD4 < 5 & dat$pop$Status==1 &
                         dat$pop$V > dat$param$vl_undetectable) # list of infectees with detectable viral loads.
  }else{
    #index of alive infectees not on tx
  infectees <- which(dat$pop$CD4 < 5 & dat$pop$Status==1  &
                       dat$pop$treated!=1)
  }
  
  cd4_threshold_time <- rep(NA_real_,length(infectees))
  for(ii in 1:4){
    ix <- which(dat$pop$CD4[infectees]==ii)
    if(length(ix)>0){
      cd4_times_index <-cbind(dat$pop$spvl_cat[infectees][ix],rep(ii,length(ix)))
      prob_increment <- 1.0/(dat$param$CD4_lookup[cd4_times_index]*365)
      cd4_threshold_time[ix] <- rbinom(length(ix),1,prob_increment)
    } 
  }
  #identify agents whose cd4 values will increase  
  cd4_increment<- which(cd4_threshold_time==1)
  
  if(length(cd4_increment)>0)
  {    
    infected_and_cd4_increment <- infectees[cd4_increment]
    dat$pop$CD4[infected_and_cd4_increment] <- dat$pop$CD4[infected_and_cd4_increment] + 1
    dat$pop$CD4_time[infected_and_cd4_increment] <- 0
    dat$pop$CD4_nadir[infected_and_cd4_increment] <-dat$pop$CD4[infected_and_cd4_increment]
    
    cd4_dead <- which(dat$pop$CD4[infected_and_cd4_increment] ==5)
    
    #this starts VL progression to aids level when cd4 aids starts
    if(dat$param$aids_death_model=="cd4"){
      if(any(dat$pop$CD4[infected_and_cd4_increment]==4)){
        new_aids_index <- which(dat$pop$CD4[infected_and_cd4_increment]==4)
        final_index <- infected_and_cd4_increment[new_aids_index]
        dat$pop$RandomTimeToAIDS[final_index] <- at
      }}
    
    
    if(length(cd4_dead)>0)
    {
      cd4_dead_final_index <- infected_and_cd4_increment[cd4_dead]
      dat$pop$CD4_time_death[cd4_dead_final_index] <- at      
    }
  }
  
  cd4_unchanged <-  which(cd4_threshold_time==0)
  if(length(cd4_unchanged)>0){dat$pop$CD4_time[cd4_unchanged] <- dat$pop$CD4_time[cd4_unchanged] +1   }
  
  #-----------------------------------
  #additional probability of death for agents 1,2,3 category
  # note! either treated or untreated
  #note: this should probably be turned into subfunction 10-14-15
  cd4_cat1<-which(dat$pop$Status==1 & dat$pop$CD4==1)
  if(length(cd4_cat1)>0){
    prob_death <- runif(length(cd4_cat1))
    death_index <- which(prob_death < dat$param$cd4_cat1_death_prob)
    if(length(death_index)>0){
       pop_index<- cd4_cat1[death_index]
       dat$pop$CD4[pop_index] <- 5
    }
  }
    cd4_cat2<-which(dat$pop$Status==1 & dat$pop$CD4==2)
    if(length(cd4_cat2)>0){
      prob_death <- runif(length(cd4_cat2))
      death_index <- which(prob_death < dat$param$cd4_cat2_death_prob)
      if(length(death_index)>0){
        pop_index<- cd4_cat2[death_index]
        dat$pop$CD4[pop_index] <- 5
      }
    }
    cd4_cat3<-which(dat$pop$Status==1 & dat$pop$CD4==3)
      if(length(cd4_cat3)>0){
        prob_death <- runif(length(cd4_cat3))
        death_index <- which(prob_death < dat$param$cd4_cat3_death_prob)
        if(length(death_index)>0){
          pop_index<- cd4_cat3[death_index]
          dat$pop$CD4[pop_index] <- 5
        }
      }
  #-----------------------------------  
  #additional death prob for agents with cd4 aids and treated
    cd4_cat4<-which(dat$pop$Status==1 & dat$pop$CD4==4 & dat$pop$treated==1)
    if(length(cd4_cat4)<1){
      prob_death <- runif(length(cd4_cat4))
      death_index <- which(prob_death < dat$param$cd4_cat4_treated_death_prob)
      if(length(death_index)>0){
        pop_index<- cd4_cat4[death_index]
        dat$pop$CD4[pop_index] <- 5
      }
    }
    
  #-----------------------------------  
  #for agents on treatment
  #update for agents at cd4 nadir
    if(dat$param$VL_Function=="aim3"){
      # Aim 3 code allows virus to rebound due to drug resistance.  Don't allow CD4 counts to increase (= a decrease in
      # CD4 category) to jump back up in patients in whom virus is not suppressed.
      # Note: It would probably be harmless to apply this to aim 2 code as well, but I am restricting this change
      # to the aim 3 code for the moment out of an abundance of caution
      treatment_index_nadir <- which(dat$pop$treated==1 & dat$pop$V < dat$param$vl_undetectable &
                                     dat$pop$CD4==dat$pop$CD4_nadir & dat$pop$CD4!=1)
    } else {
      treatment_index_nadir <- which(dat$pop$treated==1 & 
                                     dat$pop$CD4==dat$pop$CD4_nadir & dat$pop$CD4!=1)
    }                              
  if(length(treatment_index_nadir)>0){
    improvement_prob <- runif(length(treatment_index_nadir))
    improvement_index <- which(improvement_prob< dat$param$cd4_prob_incr_nadir)
    if(length(improvement_index)>0){
      pop_index <- treatment_index_nadir[improvement_index]
      dat$pop$CD4[pop_index] <- dat$pop$CD4[pop_index] - 1
      dat$pop$CD4_time[pop_index] <- 0
    }
  }
  
  #update for agents on tx and cd4= nadir - 1  
  if(dat$param$VL_Function=="aim3") {
    # See note above for treatment_index_nadir
    treatment_index_nadir_plus <- which(dat$pop$treated==1 & dat$pop$V < dat$param$vl_undetectable &
                                          (dat$pop$CD4==dat$pop$CD4_nadir-1) & dat$pop$CD4!=1)
  } else {
      treatment_index_nadir_plus <- which(dat$pop$treated==1 & 
                                         (dat$pop$CD4==dat$pop$CD4_nadir-1) & dat$pop$CD4!=1)
  }
  if(length(treatment_index_nadir_plus)>0){
    improvement_prob <- runif(length(treatment_index_nadir_plus))
    improvement_index <- which(improvement_prob< dat$param$cd4_prob_incr_nadir_minus)
    if(length(improvement_index)>0){
      pop_index <- treatment_index_nadir_plus[improvement_index]
      dat$pop$CD4[pop_index] <- dat$pop$CD4[pop_index] - 1
      dat$pop$CD4_time[pop_index] <- 0
    }
  }
  
    
  #-----------------------------------
  return(dat)
}
