SELECT sum(a.length_m), sum(a.traveltime_min), st_transform(st_collect(geom),4326) FROM pgr_Dijkstra(
  'select fid as id, source, target, length_m as cost from pedestriannetwork_lines',
    90926, 8515, false)
inner join pedestriannetwork_lines a
on edge=a.fid


select count(component), component FROM pgr_connectedComponents(
    'SELECT fid as id, source, target, length_m AS cost FROM pedestriannetwork_lines'
)
group by component
order by component desc



SELECT st_collect(st_transform(e.geom, 4326))
FROM pedestriannetwork_lines e
JOIN pgr_connectedComponents('SELECT fid as id, source, target, length_m AS cost FROM pedestriannetwork_lines') c
ON e.source = c.node OR e.target = c.node
WHERE c.component != 1  -- Assuming component 1 is the large connected component
group by c.component
ORDER BY c.component;


SELECT Find_SRID('', 'pedestriannetwork_lines', 'geom');
SELECT Find_SRID('', 'links', 'geom');
SELECT Find_SRID('', 'locations', 'geom');

with s as (
  select st_startpoint(geom) as geom from links),
e as (
  select st_endpoint(geom) from links)
SELECT 
  st_transform(st_startpoint(geom),4326) ,
  ST_Transform(geom, 4326),
  geom <-> st_startpoint(geom) AS dist
FROM
  links 
ORDER BY
  dist
LIMIT 10;



SELECT 
       st_transform(st_startpoint(links.geom), 4326),
       st_transform(st_endpoint(links.geom), 4326),
       st_transform(nodes.geom,4326),
       nodes.st_dist,
       nodes.end_dist,
       nodes.id
FROM links
CROSS JOIN LATERAL (
  select 
    nodes.id, 
    nodes.geom, 
    nodes.geom <-> st_startpoint(links.geom) AS st_dist,
    nodes.geom <-> st_endpoint(links.geom) AS end_dist
  FROM sidewalk_nodes AS nodes
  ORDER BY st_dist
  LIMIT 1
) nodes
limit 5



with st_node as (
	SELECT 
	  links.fid,
	  nodes.st_pt_id
	FROM links
	CROSS JOIN LATERAL (
	  select 
	    nodes.id as st_pt_id, 
	    nodes.geom, 
	    nodes.geom <-> st_startpoint(links.geom) AS st_dist
	  FROM sidewalk_nodes AS nodes
	  ORDER BY st_dist
	  LIMIT 1
	) nodes
),
end_node as (
	SELECT 
	  links.fid,
	  nodes.end_pt_id
	FROM links
	CROSS JOIN LATERAL (
	  select 
	    nodes.id as end_pt_id, 
	    nodes.geom, 
	    nodes.geom <-> st_endpoint(links.geom) AS st_dist
	  FROM sidewalk_nodes AS nodes
	  ORDER BY st_dist
	  LIMIT 1
	) nodes
)
select * from st_node
inner join end_node 
on st_node.fid=end_node.fid



CREATE OR REPLACE FUNCTION calculate_routes()
RETURNS TABLE(id INTEGER, length_m BIGINT, travel_time FLOAT, geom GEOMETRY) AS $$
DECLARE
    rec RECORD;
BEGIN
    -- Loop over each pair of start and end points
    FOR rec IN
        SELECT fid as id, st_pt_id, end_pt_id 
        FROM link_nearest_nodes
    LOOP
        -- Execute pgr_Dijkstra for each pair
        RETURN QUERY
        SELECT 
        	rec.id,
            SUM(ped_net.length_m) AS length_m,
            SUM(ped_net.traveltime_min) AS travel_time,
            ST_Transform(ST_Collect(ped_net.geom), 4326) AS geom
        FROM pgr_Dijkstra(
            'SELECT fid AS id, source, target, length_m AS cost FROM pedestriannetwork_lines',
            rec.st_pt_id,
            rec.end_pt_id,
            false
        ) AS agg
        JOIN pedestriannetwork_lines AS ped_net
        ON agg.edge = ped_net.fid;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
select * from calculate_routes()
inner join links on id=fid
