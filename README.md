External Validation for AKI Predictive Models using PCORnet CDM data
=====================================================================

This is the working directory building and validating predictive models for Acute Kidney Injury (AKI) based on PCORNET common data model across GPC sites.

by Xing Song, with Mei Liu, Russ Waitman
[Medical Informatics Division, Univeristy of Kansas Medical Center][MI]

[MI]: http://informatics.kumc.edu/

Copyright (c) 2018 Univeristy of Kansas Medical Center  
Share and Enjoy according to the terms of the MIT Open Source License.

***

## Background

Acute Kidney Injury (**AKI**) is a common and highly lethal health problem, affecting 10-15% of all hospitalized patients and >50% of the intensive care unit (ICU) patients. In this application, we propose to build predictive models to identify patients at risk for hospital-acquired AKI and externally validate the models using the PCORnet (Patient Centered Outcomes Research Network)13 common data model (CDM) infrastructure ([GPC#711],[GPC#742]). The project will be carried out with the following aims:

* **Aim 1 - KUMC**: Building predictive models on single-site data. We will develop and internally cross-validate machine learning based predictive models for in-hospital AKI using electronic medical record (EMR) data from the University of Kansas Medical Center’s (KUMC) PCORnet CDM. As co-I of the PCORnet network Greater Plains Collaborative (GPC), PI of this project has direct access to the KUMC CDM for model development.    
      * Task 1.1: developing R implementation for data extraction and quality check       
      * Task 1.2: exploratory data analysis (e.g. strategies for data cleaning and representation, feature engineering)     
      * Task 1.3: benchmarking with replication of current state-of-art prediction model        
      * Task 1.4: developing new models         
 
* **Aim 2 -  GPC**: Validating predictive models on multi-site data. We will implement an automated analytic package with built in data extraction and predictive modeling from Aim 1 for distributed execution within two PCORnet clinical data research networks (CDRNs), namely GPC led by Dr. Waitman and Veterans Health Administration (VHA) site led by Dr. Matheny in pSCANNER. All prototyping will be done on the KUMC CDM.    
      * Task 2.1: deploying R codes for data extraction and quanlity check, and reporting results to KUMC           
      * Task 2.2: deploying R codes for external validations of predictive models           
      
[GPC#711]: https://informatics.gpcnetwork.org/trac/Project/ticket/711
[GPC#742]: https://informatics.gpcnetwork.org/trac/Project/ticket/742

* **Aim 3**: Interpreting the AKI prediction model by analyzing and visualizing top important predictors    

* **Aim 4**: Developing the adjMMD measure to infer model transportability    

***

## Requirement
In order for sites to extract AKI cohort, run predictive models and generate final report, the following infrastructure requirement must be satisfied:

**R program**: [R Program] (>=3.3.0) is required and [R studio] (>= 1.0.136) is preferred to be installed as well for convenient report generation.    
**DBMS connection**: Valid channel should also be established between R and DBMS so that communication between R and CDM database can be supported.    
**Dependencies**: A list of core R packages as well as their dependencies are required. However, their installations have been included in the codes. 
* [DBI] (>=0.2-5): for communication between R and relational database    
* [ROracle] (>=1.3-1): an Oracle JDBC driver    
* [RJDBC]: a SQL sever driver    
* [RPostgres]: a Postgres driver    
* [rmarkdown] (>=1.10): for rendering report from .Rmd file (*Note: installation may trip over dependencies [digest] and [htmltools] (>=0.3.5), when manually installation is required*).     
* [dplyr] (>=0.7.5): for efficient data manipulation    
* [tidyr] (>=0.8.1): for efficient data manipulation    
* [magrittr] (>=1.5): to enable pipeline operation    
* [stringr] (>=1.3.1): for handling strings     
* [knitr] (>=1.11): help generate reports
* [kableExtra]: for generating nice tables
* [ggplot2] (>=2.2.1): for generating nice plots    
* [ggrepel]: to avoid overlapping labels in plots   
* [openxlsx] (>=4.1.0): to save tables into multiple sheets within a single .xlsx file      
* [RCurl]: for linkable descriptions (when uploading giant mapping tables are not feasible)
* [XML]: for linkable descriptions (when uploading giant mapping tables are not feasible)
* [xgboost]: for effectively training the gradient boosting machine   



[R Program]: https://www.r-project.org/
[R studio]: https://www.rstudio.com/
[DBI]: https://cran.r-project.org/web/packages/DBI/DBI.pdf
[ROracle]: https://cran.r-project.org/web/packages/ROracle/ROracle.pdf
[RJDBC]: https://cran.r-project.org/web/packages/RJDBC/RJDBC.pdf
[RPostgres]: https://cran.r-project.org/web/packages/RPostgres/RPostgres.pdf
[rmarkdown]: https://cran.r-project.org/web/packages/rmarkdown/rmarkdown.pdf
[dplyr]: https://cran.r-project.org/web/packages/dplyr/dplyr.pdf
[tidyr]: https://cran.r-project.org/web/packages/tidyr/tidyr.pdf
[magrittr]: https://cran.r-project.org/web/packages/magrittr/magrittr.pdf
[stringr]: https://cran.r-project.org/web/packages/stringr/stringr.pdf
[knitr]: https://cran.r-project.org/web/packages/knitr/knitr.pdf
[kableExtra]: http://haozhu233.github.io/kableExtra/awesome_table_in_html.html
[ggplot2]: https://cran.r-project.org/web/packages/ggplot2/ggplot2.pdf
[ggrepel]: https://github.com/slowkow/ggrepel
[openxlsx]: https://cran.r-project.org/web/packages/openxlsx/openxlsx.pdf
[digest]: https://cran.r-project.org/web/packages/digest/digest.pdf
[htmltools]:  https://cran.r-project.org/web/packages/htmltools/htmltools.pdf
[RCurl]: https://cran.r-project.org/web/packages/RCurl/RCurl.pdf
[XML]: https://cran.r-project.org/web/packages/XML/XML.pdf
[xgboost]:https://xgboost.readthedocs.io/en/latest/   


***


## Site Usage
The following instructions are for extracting cohort and generating final report from a `DBMS` data source (specified by `DBMS_type`) (available options are: Oracle, tSQL, PostgreSQL(not yet)) 

### Part I: Study Cohort and Variable Extraction

1. Get `AKI_CDM` code
  - **download** the [AKI_CDM] repository as a .zip file, unzip and save folder as `path-to-dir/AKI_CDM`    
  *OR*  
  - **clone** [AKI_CDM] repository (using [git command]):   
      i) navigate to the local directory `path-to-dir` where you want to save the project repository and     
      type command line: `$ cd <path-to-dir>`   
      ii) clone the AKI_CDM repository by typing command line: `$ git clone https://github.com/kumc-bmi/AKI_CDM`  


2. Prepare configeration file `config.csv` and save in the AKI_CDM project folder    
      i) **download** the `config_<DBMS_type>_example.csv` file according to `DBMS_type`      
      ii) **fill in** the content accordingly (or you can manually create the file using the following format)      
    
    |username     |password    |access         |cdm_db_name/sid                 |cdm_db_schema      |temp_db_schema |   
    |:------------|:-----------|:--------------|:-------------------------------|:------------------|:--------------|    
    |your_username|your_passwd |host:port    |database name(tSQL)/SID(Oracle) |current CDM schema |default schema |   
    
      iii) **save as** `config.csv` under the same directory         
      

[AKI_CDM]: https://github.com/kumc-bmi/AKI_CDM
[git command]: https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository



3. Extract AKI cohort and generate final report   
      i) **setup** working directory    
        - In *r-studio* environment, simply **open** R project `AKI_CDM.Rproj` within the folder
        *OR*    
        - In *plain r* environment, **set working directory** to where `AKI_CDM` locates by runing `setwd("path-to-dir/AKI_CDM")`
            
      ii) **edit** r script `render_report.R` by specifying the following parameters:   
        - `which_report`: which report you want to render (default is `./report/AKI_CDM_EXT_VALID_p1_QA.Rmd`, but there will be more options in the future)   
        - `DBMS_type`: what type of database the current CDM is built on (available options are: `Oracle`(default), `tSQL`)        
        - `driver_type`: what type of database connection driver is available (available options are: `OCI` or `JDBC` for oracle; `JDBC` for sql server)      
        - `start_date`, `end_date`: the start and end date of inclusion period, in `"yyyy-mm-dd"` format (e.g. "2010-01-01", with the quotes)             
      
      iii) **run** *Part I* of r script `render_report.R` after assigning correct values to the parameters in ii)        
      
      iv) **collect and report** all output files from `/output` folder   
        -- a. AKI_CDM_EXT_VALID_p1_QA.html - html report with description, figures and partial tables    
        -- b. AKI_CDM_EXT_VALID_p1_QA_TBL.xlsx - excel with full summary tables    

*Remark*: all the counts (patient, encounter, record) are masked as "<11" if the number is below 11


### Part II: Validate Existing Predictive Models and Retrain Predictive Models with Local Data

1. Validate the given predictive model trained on KUMC's data   

    i) **download** the predictive model package, "AKI_model_kumc.zip", from the securefile link shared by KUMC. Unzip the file and save everything under `./data/model_kumc` (remark: make sure to save the files under the correct directory, as they will be called later using the corresponding path)   
    
    ii) **continue to run** *Part II.1* of the r script `render_report.R` after completing *Part I*. *Part II.1* will only depend on tables already extracted from *Part I* (saved locally in the folder `./data/...`), no parameter needs to be set up.     

    iii) **collect and report** the two new output files from `/output` folder           
      -- a. AKI_CDM_EXT_VALID_p2_1_Benchmark.html - html report with description, figures and partial tables       
      -- b. AKI_CDM_EXT_VALID_p2_1_Benchmark_TBL.xlsx - excel with full summary tables          

2. Retrain the model using local data and validate on holdout set 

    i) **download** the data dictionary, "feature_dict.csv", from the securefile link shared by KUMC and save the file under "./ref/" (remark: make sure to save the file under the correct directory, as it will be called later using the corresponding path)   

    ii) **continue to run** *Part II.2* of the r script `render_report.R` after completing *Part I*. *Part II.2* will only depend on tables already extracted from *Part I* (saved locally in the folder `./data/...`), no parameter needs to be set up.     

    iii) **collect and report** the two new output files from `/output` folder           
      -- a. AKI_CDM_EXT_VALID_p2_2_Retrain.html - html report with description, figures and partial tables       
      -- b. AKI_CDM_EXT_VALID_p2_2_Retrain_TBL.xlsx - excel with full summary tables          
      
*Remark: As along as Part I is completed, Part II.1 and Part II.2 can be run independently, based on each site's memory and disk availability.   


### Part III: Calculate adjMMD and joint KL-divergence for top importance variables

Run the `distribution_analysis.R` script to calculate the adjMMD and joint KL-divergence of distribution hetergenity among top important variables of each model. adjMMD is an effective metric which can be used to assess and explain model transportability. 



***

## Benchmarking
a. It takes about **2 ~ 3 hours** to complete Part I (AKI_CDM_EXT_VALID_p1_QA.Rmd). At peak time, it will use about **30 ~ 40GB memory**, especially when large tables like Precribing or Lab tables are loaded in. Total size of output for Part I is about **6MB**.

b. It takes about **25 ~ 30 hours** to complete Part II.1 (AKI_CDM_EXT_VALID_p2_Benchmark.Rmd). At peak time, it will use about **40 ~ 50GB memory**, especially at the preprocessing stage. Total size of intermediate tables and output for Part II.1 is about **600MB**.

c. It takes about **40 ~ 50 hours** to complete Part II.2 (AKI_CDM_EXT_VALID_p2_Retrain.Rmd). At peak time, it will use about **50 ~ 60GB memory**, especially at the preprocessing stage. Total size of intermediate tables and output for Part II.1 is about **800MB**.

***
*updated 05/03/2019*
