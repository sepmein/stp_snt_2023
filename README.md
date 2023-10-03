# STP SNT analysis 2023
The analysis coding for São Tomé and Príncipe subnational tailoring analysis 2023.

## Project Management

### Track Progress

Clickup was used to track the progress: [ClickUp STP Analysis Tracker](https://app.clickup.com/9010032161/v/li/900202049906).

GitHub Repository:

[STP Analysis GitHub Repository](https://github.com/sepmein/stp_snt_2023). 

[Code Issues and Improvements](https://github.com/sepmein/stp_snt_2023/issues).

## Replicate of this analysis

This analysis will use R `targets` package to ensure reproducibility.

### Packages to be installed

```r
install.packages(c("targets", "tarchetypes"))
```

## Data Management

Database relationships

```mermaid
---
title: STP SNT 2023
---
erDiagram
    adm1 {
        uuid id PK, UK
        string adm1 PK, UK
    }
    adm2 {
        uuid id PK, UK
        string adm1 PK
        string adm2 PK
    }
    hf {
        uuid id PK, UK
        string adm1 PK
        string adm2 PK
        string hf PK
        string type
        string owner
        float lat
        float long
        string comment
    }
    adm3 {
        uuid id PK, UK
        string adm1 PK
        string adm2 PK
        string hf PK
        string adm3 PK
    }
    hf_raw {
        string adm1 PK, FK
        string adm2 PK, FK
        string hf PK, FK, UK
        string type
        string owner
        float lat
        float long
        string comment
    }
    pop_adm1 {
        string adm1 PK, FK
        int year PK
        string sex
        string age_group
        int pop
    }
    pop_adm2 {
        string adm1 PK, FK
        string adm2 PK, FK, UK
        int year PK
        string sex
        int pop
    }
    routine {
        string adm1 PK, FK
        string hf PK, FK
        string month PK
        int year PK
        string group PK
        int susp
        int test
        int conf
        int negative
        int treat
        int maladm
        int severe
        int alldth
        int maldth
    }
    elimination {
        int no
        string no_order
        string adm1 PK, FK
        string adm2 PK, FK, UK
        int cases_2018
        int cases_2019
        int cases_2020
        int cases_2021
        int cases_2022
        string elimination
    }
    passive_cases_2022 {
        string month PK
        string hf PK, FK
        string adm1 PK, FK
        string adm2 PK, FK
        int age
        string sex
    }
    reative_cases_2022 {
        string month PK
        string hf PK, FK
        string adm1 PK, FK
        string adm2 PK, FK
        int age
        string sex
    }
    intervention {
        string adm1 PK, FK
        string hf PK, FK
        int year PK
        string month PK
        int anc1
        int anc2
        int anc3
        int anc4
        int ipt1
        int ipt2
        int ipt3
        int ipt4
        int itn_p
        int itn_v
        int stock
    }
    irs {
        string adm1 PK, FK
        string adm2 PK, FK
        int year PK
        int cycle_1
        int cycle_2
        int treated
        int closed
        int refused
        int not_treated
        int irs_planned
        float cover
        int uninhabited
        int other
        int total
        int pop
        int insecticide
    }
    itn_campaign {
        string adm1 PK, FK
        int itn
    }
    itn_routine {
        string adm1 PK, FK
        int year PK
        int itn_u5
        int int_p
        int itn_other
        int itn
    }
    lsm {
        string adm1 PK, FK
        string adm2 PK, FK
        float area
        float scanned
        int water_bodies
        int sprayed
        int issued
        int unsprayed
        date last_spray
        int sampled
        int positive
        float average_anopheles
    }
    vector {
        string adm1 PK, FK
        string adm2 PK, FK
        int year PK
        string month PK
        int mos_adult_inside
        int mos_adult_outside
        int lav_1
        int lav_2
        int lav_3
        int lav_4
        int pupa
    }
    adm1 ||--o| adm2: contains
    adm2 ||--o| hf: contains
    adm2 ||--o| adm3: contains
    hf_raw ||--|| hf: match
    hf ||--o| adm3: contains

    adm1 ||--o| pop_adm1: has
    adm1 ||--o| itn_campaign: has
    adm1 ||--o| itn_routine: has

    adm2 ||--o| pop_adm2: has
    adm2 ||--o| elimination: has
    adm2 ||--o| irs: has
    adm2 ||--o| lsm: has
    adm2 ||--o| vector: has
    
    hf ||--o| passive_cases_2022: has
    hf ||--o| reative_cases_2022: has
    hf ||--o| intervention: has
    hf ||--o| routine: has





```