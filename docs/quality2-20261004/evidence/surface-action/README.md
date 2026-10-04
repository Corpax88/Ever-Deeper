# Surface action placement

The first Mac journey image shows DESCEND covering the lower hero frame at the Mossvein entrance. On mobile, Surface actions now use the unused mining slot while Mine is hidden. The Bag shifts only36logicalpx to preserve the18px gap; all action sizes and approved icons remain. Mining restores the existing placement. No change applies to cave actions or to Surface resource mining while Mine is shown.

The actual native production overlay passes21/21 checks at667/844/932: whole-hero clearance, on-screen separated controls, preserved target size, real touch descent and restored Bag/Mine separation. The667 and932 images were inspected. The initial probe used viewport coordinates as window touch coordinates; its touch checks failed until the probe applied the final viewport transform. Production did not change between those runs.

This is scoped native rendering; the following Mac acceptance must verify the integrated runtime and actual mobile touch.
