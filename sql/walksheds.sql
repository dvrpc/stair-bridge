set search_path to :schema, public;

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
            50) 
    group by a.fid
)
select 
    wt.node_id,
    st_collect(pedestriannetwork_lines.geom) AS isochrone_geom
from 
    walk_time wt,
    lateral pgr_drivingDistance(
        'select fid as id, source, target, traveltime_min as cost from pedestriannetwork_lines', 
        wt.node_id,                 
        15,
        false                       
    ) as dr
join 
    pedestriannetwork_lines
on 
    dr.edge = pedestriannetwork_lines.fid
group by wt.node_id;


drop table if exists isoshells;
create table isoshells as 
with hull as (
  select st_concavehull(isochrone_geom,0.2) as geom
  from isochrones 
) 
select row_number() over() as gid, geom as geom from hull 
