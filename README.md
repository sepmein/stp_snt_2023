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
    resistance {
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
    adm2 ||--o| resistance: has
    
    hf ||--o| passive_cases_2022: has
    hf ||--o| reative_cases_2022: has
    hf ||--o| intervention: has
    hf ||--o| routine: has
```
### Match adm1, adm2 and hf

Approaches used:

```mermaid
flowchart TD
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

#### hf

1. hf in routine database
mismatch after fuzzy matching

POSTO DE QUARTEL


### GIS
#### Shapefiles

1. aligned shapefiles
> Problem

![align_shapefiles](<documentation/1. discrepencies between adm1 adm2 and village level shapefile.png>)

![align_shapefiles](<documentation/2. discrepencies between adm1 adm2 and village level shapefile.png>)

Green shapefile was provided by NMCP with detailed village level of information. Orange one was from WHO GISHUB. The unaligned borders between the two was noticed.

A aligned shapefile with adm1/adm2/adm3 level of information should be created before the analysis.

> Solution

I used the crs reprojection with the geo-referencing in QGIS to manually aligned the two islands.

2. localites names same
During the process, I found some of the localites and adm2 name are the same, but with different area. I will use the adm2 shapefile and generate a list of localites with duplicated names. Those duplicates could be treated as two classes, the first one, same name with adjacent area, the second one, same name without any adjacent area.

3. check localites names with the 