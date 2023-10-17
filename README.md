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
    adm1["adm1 distrito"] {
        uuid id PK, UK
        string adm1 PK, UK
    }
    adm2["adm2 localidade"] {
        uuid id PK, UK
        string adm1 PK
        string adm2 PK
    }
    hf["US"] {
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
    elimination["Casos por localidade"] {
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
    passive_cases_2022["Passiva Casos"] {
        string month PK
        string hf PK, FK
        string adm1 PK, FK
        string adm2 PK, FK
        int age
        string sex
    }
    reative_cases_2022["Vig. reactiva"] {
        string month PK
        string hf PK, FK
        string adm1 PK, FK
        string adm2 PK, FK
        int age
        string sex
    }
    intervention["Intervenções de rotina"] {
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
    irs["PID"] {
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
    itn_campaign["MTILD (Massa)"] {
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
    lsm["gerenciamento de fonte de larvas"] {
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
    vector["Ab. vectores"] {
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
    resistance["resistência a inseticidas"] {
        string adm1 PK, FK
        string adm2 PK, FK
        int year PK
        string month PK
        string insecticide
        float mortality
        string resistance
    }
    adm1 ||--o| adm2: contains
    adm2 ||--o| hf: contains
    hf_raw ||--|| hf: match

    adm1 ||--o| pop_adm1: has
    adm1 ||--o| itn_campaign: has
    adm1 ||--o| itn_routine: has

    adm2 ||--o| pop_adm2: has
    adm2 ||--o| elimination: has
    adm2 ||--o| irs: has
    adm2 ||--o| lsm: has
    adm2 ||--o| vector: has
    adm2 ||--o| resistance: has
    
    hf ||--o| passive_cases_2022: has
    hf ||--o| reative_cases_2022: has
    hf ||--o| intervention: has
    hf ||--o| routine: has
```

### Match adm1, adm2 and hf

Approaches used:

```mermaid
flowchart LR 
    A[adm1 shapefile] -->|Get unique adm1| B(Unique adm1 in shapefile)
    C[routine db] -->|Get unique adm1| D(Unique adm1 in routine db)
    B --> E{fuzzy join by string distance}
    D --> E
    E --> F{Remove the exact same match}
    F --> G{Manually check and fix}
    G --> H{Match function for routine db}
    H --> I[Aligned adm1 for shapefile and routine]
```

```mermaid
flowchart LR
    A[Fix ADM1] --> B(Fix ADM2)
    B --> C(Fix HF)
    C
```

#### adm1
In adm1_from_itn_route, there is an extra adm1 called "CNE", which might stands for National Center for Endemic Diseases (CNE) (Sao Tome and Principe). Not sure why, set CNE to NA firstly


#### hf

1. hf in routine database
mismatch after fuzzy matching

- POSTO DE QUARTEL
- P. SAÚDE DE V. D´AMÉRICA
- POSTO DE QUARTEL
- HOSPITAL DOUTOR QUARESMA DIAS DA GRAÇA
- POSTO DE NOVA APOSTÓLICA
- POSTO DE ÁGUA ARROZ
- POSTO SAÚDE DE PINHEIRA ROÇA
- P. S. DE RIBEIRA AFONSO should it be Ribeira Afonso I or Ribeira Afonso II(Sta Infancia)?
- P. S. IRMÃS C. DE R. AFONSO should it be Ribeira Afonso I or Ribeira Afonso II(Sta Infancia)?

### GIS
#### Shapefiles

##### Align shapefiles
> Problem

![align_shapefiles](<documentation/1. discrepencies between adm1 adm2 and village level shapefile.png>)

![align_shapefiles](<documentation/2. discrepencies between adm1 adm2 and village level shapefile.png>)

Green shapefile was provided by NMCP with detailed village level of information. Orange one was from WHO GISHUB. The unaligned borders between the two was noticed.

A aligned shapefile with adm1/adm2/adm3 level of information should be created before the analysis.

> Solution

I used the crs reprojection with the geo-referencing in QGIS to manually aligned the two islands.

##### Fix same localites names with same and different adm1

During the process, I found some of the localites has the exact same name, some of them located in the same district, others don't.

The shapefile country shared with us has duplicated records with the exact same adm1 and adm2. There are records with identical adm1 and adm2 values, some of which are adjacent to each other, while others are not. Attached is the list detailing these duplicates.

I have conducted a preliminary analysis and before proceeding further, I need confirmation from the country office on the following points:

- Merging Adjacent Duplicates:
Is it permissible to merge the records that are adjacent to each other, considering they share the same adm1 and adm2 values?

- Review of Non-Adjacent Duplicates:
For the records that are not adjacent but have identical adm1 and adm2 values, country need to review and confirm if these instances are due to naming errors or map inaccuracies? Additionally, it would be helpful to receive guidance on how to proceed with these records. 

##### the creation of the Health facility shapefile, the decision of Unit of analysis

> Problem
We have a shapefile with adm2 level. I need to create a hf level shapefile. There are two approaches:

1. The first approach
    - For each adm2, I calculated the closest HF. 
    - Assign a HF value to each adm2
    - For each HF group, union all the adm2s
    
The problem is that it is that for each HF group, there will be multiple adm1s. Country will be deciding the unit of analysis.
    
2. The second approach
    - Create adm1 shp based on adm2 shp
    - Within each adm1, for each adm2, calculate the closest HF
    - Assign a HF value to each adm2
    - For each HF group, union all the adm2s

##### HFs without any data

1. Uba Budo in Cantagalo.
2. Hospital Principe in Principe.

##### HFs with incorrect GPS

1. Porto Alegre POINT (6.63361 0.03556)
2. Santana POINT (6.74718 0.25813)

Resides outside of the adm1.
