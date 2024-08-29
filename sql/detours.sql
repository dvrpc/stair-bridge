SET search_path TO :schema, public;

create table if not exists link_nearest_nodes as
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
select a.fid, a.st_pt_id, b.end_pt_id from st_node a
inner join end_node b
on a.fid=b.fid;



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
create table if not exists detours as
select a.id, b.num, a.length_m, a.travel_time, a.geom from calculate_routes() a
inner join links b on id=fid
