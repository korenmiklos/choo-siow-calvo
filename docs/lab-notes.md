# 2025-10-21
## Setting up the pipeline from .dta to edge list

```sql
D describe table edges;
┌──────────────────┬─────────────┬─────────┬─────────┬─────────┬─────────┐
│   column_name    │ column_type │  null   │   key   │ default │  extra  │
│     varchar      │   varchar   │ varchar │ varchar │ varchar │ varchar │
├──────────────────┼─────────────┼─────────┼─────────┼─────────┼─────────┤
│ frame_id_numeric │ BIGINT      │ YES     │ NULL    │ NULL    │ NULL    │
│ person_id        │ INTEGER     │ YES     │ NULL    │ NULL    │ NULL    │
│ T                │ DOUBLE      │ YES     │ NULL    │ NULL    │ NULL    │
│ lnR              │ DOUBLE      │ YES     │ NULL    │ NULL    │ NULL    │
│ lnY              │ DOUBLE      │ YES     │ NULL    │ NULL    │ NULL    │
│ lnL              │ DOUBLE      │ YES     │ NULL    │ NULL    │ NULL    │
└──────────────────┴─────────────┴─────────┴─────────┴─────────┴─────────┘
D select count(distinct frame_id_numeric) from edges;
┌──────────────────────────────────┐
│ count(DISTINCT frame_id_numeric) │
│              int64               │
├──────────────────────────────────┤
│             1029931              │
│          (1.03 million)          │
└──────────────────────────────────┘
D select count(distinct person_id) from edges;
┌───────────────────────────┐
│ count(DISTINCT person_id) │
│           int64           │
├───────────────────────────┤
│          1290611          │
│      (1.29 million)       │
└───────────────────────────┘
```