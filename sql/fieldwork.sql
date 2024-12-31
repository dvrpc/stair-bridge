drop table if exists :schema.fieldwork cascade;
create table if not exists :schema.fieldwork
(id varchar, width varchar , overgrown varchar, lighting varchar, material varchar, handrail varchar, alternatives varchar, notes varchar);

copy :schema.fieldwork from :'field_csv' CSV HEADER ;

create or replace view :schema.links_joined as 
select b.*, a.geom from :schema.links a
inner join :schema.fieldwork b
on a.num=b.id
