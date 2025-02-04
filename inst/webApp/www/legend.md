## Legend
### JSON output
ProToDeviseR outlines the following features for your protein:  
* **Regions**. At the moment, ProToDeviseR assigns regions colours *anew* for each protein (Figure 1a). A user-selected gradient is used, where regions with the same name will have the same colour. Please note that, although coloured the same within one protein, regions may have another colour assigned to them in another protein. Shapes are:
  * pointed: long regions (> 200 amino acids)
  * curved: medium-sized regions (35-200 amino acids)
  * straight: small regions (< 35 amino acids)
  * jagged: short regions designated as *repeats* (< 70 amino acids)
* **Motifs**. Most common motifs and other unstructured regions are covered (Figure 1b).
* **Markups**. Most common post-translational modification sites and other sites features are covered (Figure 1c).

![](./screenshots/features.svg) 

**Figure 1. Protein features.** **A) Regions.** Long, medium, short and three repeats. **B) Motifs.** Signal peptide (1), Coiled coil (2), Low complexity (3), Intrinsic disorder (4), Intrinsically disordered binding (5), Charged or polar amino acids patch (6), Phosphorylation motif (7), Glycosylation motif (8), Transmembrane part (9), Lipidation motif (10), Cleavage motif (11), Degradation motif (12), Targeting motif (13), Nuclear localisation or export motif (14), Docking, ligand or binding motif (15), Activity-related motif (16), Other motif (17). **C) Markups.** N-glycosylation (1), O-glycosylation (2), Glycosaminoglycan (3), C-mannosylation (4), O-fucosylation (5), Glycosylation unspecified (6), Hydroxylation (7), Prenylated (8), Acylated (9), GPI (10), Lipidation (11), Acetylation (12), Methylation (13), Amidation (14), Pyrrolidone carboxylic acid (15), Sulfation (16), D-isomerization (17), di-Sulfide bond (18), Cross-linking (19), Sumoylation (20), Ubiquitination (21), Degradation (22), Cleavage (23), Sorting (24), Targeting (25), Retaining (26), Absorption (27), Nuclear import (28), Nuclear export (29), Nuclear receptor (30), Nuclear-related (31), DNA-binding (32), Binding site (33), Ligand binding (34), Ligand site (35), Docking (36), Interacts with (37), Flavin-binding (38), Co-factor (39), Active site (40), Catalytic activity (41), Activity regulation (42), Phospho-Serine (43), Phospho-Threonine (44), Phospho-Tyrosine (45), Phosphorylation unspecified (46), Other motif (47).

### Editing the JSON file
You can manually edit the produced JSON code, either directly in the box or after download. For example, if you are analysing several proteins, you may wish to have the same colour for domains of the same type, but found in the different protein. The JSON syntax is extensively covered [elsewhere](https://pfam-docs.readthedocs.io/en/latest/guide-to-graphics.html#domain-graphics-tool).
