set search_path to :schema, public;

-- adjust this for walk time. 15 = 15 minutes walking at speed set in setup.sql
\set WALKTIME 15 

----------------------------------------------------------
--- Walkshed Creation 
----------------------------------------------------------

drop table if exists isochrones;
create table isochrones as
with walk_time as (
    select 
        a.fid as link_id,
        min(b.id) as node_id 
    from 
        links a
    join 
        sidewalk_nodes b 
    on
        st_dwithin(
            st_transform(st_centroid(a.geom), 26918),
            st_transform(b.geom, 26918),
            100) 
    group by a.fid
)
select 
    wt.link_id,
    st_collect(pedestriannetwork_lines.geom) AS isochrone_geom
from 
    walk_time wt,
    lateral pgr_drivingDistance(
        'select fid as id, source, target, traveltime_min as cost from pedestriannetwork_lines', 
        wt.node_id,                 
        :'WALKTIME',
        false                       
    ) as dr
join 
    pedestriannetwork_lines
on 
    dr.edge = pedestriannetwork_lines.fid
group by wt.link_id;


drop table if exists isoshells;
create table isoshells as 
with hull as (
  select link_id, st_concavehull(isochrone_geom,0.2) as geom
  from isochrones 
) 
select link_id,num, hull.geom as geom from hull 
inner join links 
on link_id=fid
