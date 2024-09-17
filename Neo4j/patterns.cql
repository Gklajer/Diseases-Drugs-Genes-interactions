// Load nodes
LOAD CSV WITH HEADERS FROM "file:///nodes.csv" AS row
CREATE (n:Node)
SET n=row

// Load edges
LOAD CSV WITH HEADERS FROM "file:///edges.csv" AS row
MATCH (p:Node), (o:Node)
WHERE p.Id = row.Source AND o.Id = row.Target
CREATE (p)-[edge:Edge]->(o)
SET edge=row

// Match Diseases with a common treatment
MATCH (d1 {category: "Disease"}) <-- (c {category: "Chemical"}) --> (d2 {category: "Disease"})
WHERE d1.Id <> d2.Id
MERGE (d1) -[r:Edge {category: "WITH_COMMON_TREATMENT"}]-> (d2)
ON CREATE SET r.Weight = 1
ON MATCH SET r.Weight = r.Weight + 1

// Retrieve Diseases with a common treatment 
MATCH (d1) -[r:Edge {category: "WITH_COMMON_TREATMENT"}]->(d2)
RETURN DISTINCT d1.Id AS Source, d2.Id AS Target, "WITH_COMMON_TREATMENT" AS category, r.Weight AS Weight

// Match Diseases connected "directly" (not via another Disease) to a Gene
MATCH (g {category: "Gene"})<--({category: "Variant"})-->({category: "Chemical"})-->(d {category: "Disease"})
MERGE (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (d)
ON CREATE SET r.Weight = 1
ON MATCH SET r.Weight = r.Weight + 1
UNION
MATCH (g {category: "Gene"})-->({category: "Chemical"})-->(d {category: "Disease"})
MERGE (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (d)
ON CREATE SET r.Weight = 1
ON MATCH SET r.Weight = r.Weight + 1
UNION
MATCH (g {category: "Gene"})<--({category: "Variant"})-->({category: "Variant+Chemical"})<--({category: "Chemical"})-->(d {category: "Disease"})
MERGE (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (d)
ON CREATE SET r.Weight = 1

// Retrieve Diseases connected "directly" (not via another Disease) to a Gene
MATCH (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (d)
RETURN DISTINCT g.Id AS Source, d.Id AS Target, "ASSOCIATED_WITH" AS category, r.Weight AS Weight

// Match Chemicals connected "directly" (not via another Disease, or Chemical) to a Gene
MATCH (g {category: "Gene"})<--({category: "Variant"})-->(c {category: "Chemical"})
MERGE (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (c)
ON CREATE SET r.Weight = 1
ON MATCH SET r.Weight = r.Weight + 1
UNION
MATCH (g {category: "Gene"})-[r]->(c {category: "Chemical"})
SET r.category = "ASSOCIATED_WITH", r.Weight = coalesce(r.Weight, 0) + 1
UNION
MATCH (g {category: "Gene"})<--({category: "Variant"})-->({category: "Variant+Chemical"})<--(c {category: "Chemical"})
MERGE (g) -[r:Edge {category: "ASSOCIATED_WITH"}]-> (c)
ON CREATE SET r.Weight = 1
ON MATCH SET r.Weight = r.Weight + 1

// Retrieve Chemicals connected "directly" (not via another Disease, or Chemical) to a Gene
MATCH (g) -[r:Edge {category: "ASSOCIATED_WITH"}]->(c {category: "Chemical"})
RETURN DISTINCT g.Id AS Source, c.Id AS Target, "ASSOCIATED_WITH" AS category, r.Weight AS Weight