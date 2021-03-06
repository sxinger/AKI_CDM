############################
#### Data Preprocessing ####
############################
rm(list=ls()); gc()

source("./R/util.R")

require_libraries(c("tidyr",
                    "dplyr",
                    "magrittr",
                    "stringr",
                    "broom",
                    "purrr",
                    "Matrix"))


# experimental design parameters
#-----prediction point
pred_in_d_opt<-c(2,1)

#-----prediction tasks
# pred_task_lst<-c("stg2up","stg1up","stg3")
pred_task_lst<-c("stg02up","stg01","stg12up")


#------data preprocessing method
# location of pre-processed data
data_file_path<-"~/data/raw"

# parameters for data preprocessing
# proc_param<-list(proc_method="mrv", #most recent value
#                  pred_end=999)

proc_param<-list(proc_method="ds",  #discrete survival
                 pred_end=7)


# collect and format variables on daily basis 
n_chunk<-4 # adjust for better efficiency

tbl1<-readRDS(paste0(data_file_path,"/Table1.rda")) %>%
  dplyr::mutate(yr=as.numeric(format(strptime(ADMIT_DATE, "%Y-%m-%d %H:%M:%S"),"%Y")))

#--by chunks: encounter year
enc_yr<-tbl1 %>%
  dplyr::select(yr) %>%
  unique %>% arrange(yr) %>%
  filter(yr>2009) %>%
  dplyr::mutate(chunk=ceiling((yr-2009)/(n()/n_chunk)))

#--by variable type
var_type<-c("demo","vital","lab","dx","px","med")

for(pred_in_d in pred_in_d_opt){
  
  if (proc_param$proc_method=="ds"){
    #--determine update time window
    tw<-as.double(seq(0,proc_param$pred_end))
    if(pred_in_d>1){
      tw<-tw[-seq_len(pred_in_d-1)]
    } 
  }
  
  #--save results as array
  for(pred_task in pred_task_lst){
    start_tsk<-Sys.time()
    cat("Start variable collection for task",pred_task,".\n")
    #---------------------------------------------------------------------------------------------
    
    X_proc<-c()
    y_proc<-c()
    proc_bm<-c()
    rsample_idx<-c()
    
    for(i in seq_len(n_chunk)){
      start_i<-Sys.time()
      cat("...start variable collection for year chunk",i,".\n")
      
      #--collect end_points
      yr_i<-enc_yr$yr[enc_yr$chunk==i]
      dat_i<-tbl1 %>% filter(yr %in% yr_i) %>%
        dplyr::select(ENCOUNTERID,yr,
                      NONAKI_SINCE_ADMIT,
                      AKI1_SINCE_ADMIT,
                      AKI2_SINCE_ADMIT,
                      AKI3_SINCE_ADMIT) %>%
        gather(y,dsa_y,-ENCOUNTERID,-yr) %>%
        filter(!is.na(dsa_y)) %>%
        dplyr::mutate(y=recode(y,
                               "NONAKI_SINCE_ADMIT"=0,
                               "AKI1_SINCE_ADMIT"=1,
                               "AKI2_SINCE_ADMIT"=2,
                               "AKI3_SINCE_ADMIT"=3)) %>%
        dplyr::mutate(y=as.numeric(y))
      
      if(pred_task=="stg1up"){
        dat_i %<>%
          group_by(ENCOUNTERID) %>%
          dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
          # dplyr::filter(!(last_stg>=1&y==0)) %>%            #filter out earlier days of AKI>=1     
          dplyr::mutate(y=as.numeric(y>0)) %>%
          
          group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else
        if(pred_task=="stg2up"){
        dat_i %<>%
          group_by(ENCOUNTERID) %>%
          dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
          # dplyr::filter(!((last_stg>=2&y==0)|               #filter out earlier days of AKI>=2
          #                  last_stg==1)) %>%                #filter out entire AKI1 encounters
          dplyr::mutate(y=as.numeric(y>=2)) %>%
          group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else
        if(pred_task=="stg3"){
        dat_i %<>%
          group_by(ENCOUNTERID) %>%
          dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
          # dplyr::filter(!((last_stg==2&y==0)|               #filter out earlier days of AKI=3
          #                  last_stg %in% c(1,2))) %>%       #filter out entire AKI1,2 encounters
          dplyr::mutate(y=as.numeric(y>2)) %>%
          group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else
        if(pred_task=="stg02up"){
          dat_i %<>%
            group_by(ENCOUNTERID) %>%
            dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
            dplyr::filter(!((last_stg>1&y==0)|              #filter out earlier days of AKI=2,3
                             last_stg %in% c(1))) %>%       #filter out entire AKI1 encounters
            dplyr::mutate(y=as.numeric(y>=2)) %>%
            group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else
        if(pred_task=="stg01"){
          dat_i %<>%
            group_by(ENCOUNTERID) %>%
            dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
            dplyr::filter(!((last_stg=1&y==0)|                #filter out earlier days of AKI=1
                             last_stg %in% c(2,3))) %>%       #filter out entire AKI2,3 encounters
            dplyr::mutate(y=as.numeric(y==1)) %>%
            group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else
        if(pred_task=="stg12up"){
          dat_i %<>%
            group_by(ENCOUNTERID) %>%
            dplyr::mutate(last_stg=max(y)) %>% ungroup %>% 
            dplyr::filter(!((last_stg>1&y==0)|                 #filter out earlier days of AKI=2,3
                              last_stg %in% c(0))) %>%         #filter out entire AKI0 encounters
            dplyr::mutate(y=as.numeric(y>1)) %>%
            group_by(ENCOUNTERID) %>% top_n(n=1L,wt=dsa_y) %>% ungroup
      }else{
        stop("prediction task is not valid!")
      }
      
      #--random sampling
      rsample_idx %<>%
        bind_rows(dat_i %>% 
                    dplyr::select(ENCOUNTERID,yr) %>%
                    unique %>%
                    dplyr::mutate(cv10_idx=sample(1:10,n(),replace=T)))
      
      #--ETL variables
      var_etl_bm<-c()
      for(v in seq_along(var_type)){
        start_v<-Sys.time()
        
        #extract
        var_v<-readRDS(paste0(data_file_path,"/AKI_",toupper(var_type[v]),".rda")) %>%
          semi_join(dat_i,by="ENCOUNTERID")
        
        if(var_type[v] != "demo"){
          if(var_type[v] == "med"){
            var_v %<>% 
              transform(value=strsplit(value,","),
                        dsa=strsplit(dsa,",")) %>%
              unnest(value,dsa) %>%
              dplyr::mutate(value=as.numeric(value),
                            dsa=as.numeric(dsa))
          }
          var_v %<>% filter(dsa <= proc_param$pred_end)
        }
        
        #transform
        var_v<-format_data(dat=var_v,
                           type=var_type[v],
                           pred_end=proc_param$pred_end)
        
        if(proc_param$proc_method=="ds"){
          Xy_proc<-get_dsurv_temporal(dat=var_v,
                                      censor=dat_i,
                                      tw=tw,
                                      pred_in_d=pred_in_d)
        }else 
          if(proc_param$proc_method=="mrv"){
            Xy_proc<-get_most_recent(dat=var_v,
                                     censor=dat_i,
                                     pred_in_d=pred_in_d)
            
        }else{
          stop("please specify the correct proc_method=c('ds','mrv')!")
        }
        
        #load
        X_proc %<>% bind_rows(Xy_proc$X) %>% unique
        y_proc %<>% bind_rows(Xy_proc$y) %>% unique
        
        lapse_v<-Sys.time()-start_v
        var_etl_bm<-c(var_etl_bm,paste0(lapse_v,units(lapse_v)))
        cat("\n......finished ETL",var_type[v],"for year chunk",i,"in",lapse_v,units(lapse_v),".\n")
      }

      lapse_i<-Sys.time()-start_i
      var_etl_bm<-c(var_etl_bm,paste0(lapse_i,units(lapse_i)))
      cat("\n...finished variabl collection for year chunk",i,"in",lapse_i,units(lapse_i),".\n")
      
      proc_bm %<>%
        bind_rows(data.frame(bm_nm=c(var_type,"overall"),
                             bm_time=var_etl_bm,
                             chunk=rep(i,length(var_type)+1),
                             stringsAsFactors = F))
    }
    
    #--save preprocessed data
    data_ds<-list(rsample_idx,
                  list(X_proc=X_proc,y_proc=y_proc),
                  proc_bm)
    
    saveRDS(data_ds,file=paste0("./data/preproc/data_",proc_param$proc_method,"_",pred_in_d,"d_",pred_task,".rda"))
    
    #---------------------------------------------------------------------------------------------
    lapse_tsk<-Sys.time()-start_tsk
    cat("\nFinish variable ETL for task:",pred_task,"in",pred_in_d,"days",",in",lapse_tsk,units(lapse_tsk),".\n")
  }
}



