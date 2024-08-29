SET search_path TO :schema, public;

alter table pedestriannetwork_lines add column if not exists source integer;
alter table pedestriannetwork_lines add column if not exists target integer;
alter table pedestriannetwork_lines add column if not exists length_m integer;

select pgr_createTopology('pedestriannetwork_lines', 1, 'geom', 'fid');

create or replace view sidewalk_nodes as 
    select id, st_centroid(st_collect(pt)) as geom
    from (
        (select source as id, st_startpoint(geom) as pt
        from pedestriannetwork_lines
        ) 
    union
    (select target as id, st_endpoint(geom) as pt
    from pedestriannetwork_lines
    ) 
    ) as foo
    group by id;

update pedestriannetwork_lines set length_m = st_length(st_transform(geom,26918));
alter table pedestriannetwork_lines add column if not exists traveltime_min double precision;
update pedestriannetwork_lines set traveltime_min = length_m  / 4820.0 * 60; -- 4.82 kms per hr, about 3 mph. walking speed.")
