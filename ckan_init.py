from pandas.api import types as ptypes
from shapely.geometry import mapping

import json
import re

import ckanapi
import geopandas as gpd
import pandas as pd
import requests


def get_type(series):
    if series.name == 'geometry':
        return 'text'

    distinct_count = series.nunique()
    value_count = series.nunique(dropna=False)

    if ptypes.is_bool_dtype(series) or (distinct_count == 2 and pd.api.types.is_numeric_dtype(series)):
        return 'bool'
    elif ptypes.is_datetime64_dtype(series):
        return 'datetime'
    elif ptypes.is_numeric_dtype(series):
        return 'numeric'
    else:
        return 'text'

def get_fields(data):
    return [{
        'id': x,
        'type': get_type(data[x])
    } for x in data.columns]

if __name__ == '__main__':
    apikey = input('What\'s your CKAN API key?\n')
    ckan = ckanapi.RemoteCKAN(
        address='http://localhost:5000',
        apikey=apikey
    )

    organization = input('What\'s your organization\'s name?\n')
    organization = ckan.action.organization_create(
        name=re.sub('[^0-9a-zA-Z]+', '-', organization).lower(),
        title=organization
    )

    vocabs = json.loads(requests.get('https://ckan0.cf.opendata.inter.sandbox-toronto.ca/api/3/action/vocabulary_list').content)
    vocabs = {
        x['name']: [t['name'] for t in x['tags']] for x in vocabs['result']
    }

    for vocab_name, tags in vocabs.items():
        v = ckan.action.vocabulary_create(name=vocab_name)
        print('Vocabulary {0} successfully created'.format(vocab_name))

        for t in tags:
            ckan.action.tag_create(
                name=t,
                vocabulary_id=v['id']
            )

        print('Vocabulary {0} successfully populated with tags'.format(vocab_name))

    package_document = ckan.action.package_create(
        name='example-document-data',
        title='Example Document Data',
        private=False,
        owner_org=organization['id'],
        dataset_category='Document',
        is_retired='false',
        pipeline_stage='Published',
        refresh_rate='Daily',
        require_legal='false',
        require_privacy='false',
        owner_type='Official',
        published_date='2019-01-01',
        approved_date='2019-01-01',
        information_url='',
        excerpt='Example package containing resource in the filestore',
        notes='A sample of BodySafe data from City of Toronto Open Data Portal',
    )

    ckan.action.resource_create(
        package_id=package_document['id'],
        name='Document Data',
        resource_type='upload',
        url='./ckan_init/BodySafe Data.csv',
        format='CSV',
        is_preview='false'
    )

    print('Sample document package successfully created and populated with resource')

    tabular = pd.read_csv('./ckan_init/BodySafe Data.csv')
    package_tabular = ckan.action.package_create(
        name='example-tabular-data',
        title='Example Tabular Data',
        private=False,
        owner_org=organization['id'],
        dataset_category='Tabular',
        is_retired='false',
        pipeline_stage='Published',
        refresh_rate='Daily',
        require_legal='false',
        require_privacy='false',
        owner_type='Official',
        published_date='2019-01-01',
        approved_date='2019-01-01',
        information_url='',
        excerpt='Example package containing resource with tabular content in the datastore',
        notes='A sample of BodySafe data from City of Toronto Open Data Portal',
    )

    ckan.action.datastore_create(
        resource={
            'package_id': package_tabular['id'],
            'name': 'Tabular Data',
            'format': 'CSV',
            'is_preview': 'true'
        },
        fields=get_fields(tabular),
        records=tabular.to_dict('records')
    )

    print('Sample tabular package successfully created and populated with resource')

    points = gpd.read_file('./ckan_init/Bicycle Shops Data.geojson')
    points['geometry'] = points['geometry'].apply(lambda x: json.dumps(mapping(x)))

    package_points = ckan.action.package_create(
        name='example-geospatial-points-data',
        title='Example Geospatial Points Data',
        private=False,
        owner_org=organization['id'],
        dataset_category='Map',
        is_retired='false',
        pipeline_stage='Published',
        refresh_rate='Daily',
        require_legal='false',
        require_privacy='false',
        owner_type='Official',
        published_date='2019-01-01',
        approved_date='2019-01-01',
        information_url='',
        excerpt='Example package containing resource with points geospatial content in the datastore',
        notes='A sample of Bicycle Shops data from City of Toronto Open Data Portal',
    )

    ckan.action.datastore_create(
        resource={
            'package_id': package_points['id'],
            'name': 'Points Data',
            'format': 'GEOJSON',
            'is_preview': 'true'
        },
        fields=get_fields(points),
        records=points.to_dict('records')
    )

    print('Sample maps package (points) successfully created and populated with resource')

    polygons = gpd.read_file('./ckan_init/City Wards Data.geojson')
    polygons['geometry'] = polygons['geometry'].apply(lambda x: json.dumps(mapping(x)))

    package_polygons = ckan.action.package_create(
        name='example-geospatial-polygons-data',
        title='Example Geospatial Polygons Data',
        private=False,
        owner_org=organization['id'],
        dataset_category='Map',
        is_retired='false',
        pipeline_stage='Published',
        refresh_rate='Daily',
        require_legal='false',
        require_privacy='false',
        owner_type='Official',
        published_date='2019-01-01',
        approved_date='2019-01-01',
        information_url='',
        excerpt='Example package containing resource with polygons geospatial content in the datastore',
        notes='The City Wards data from City of Toronto Open Data Portal',
    )

    ckan.action.datastore_create(
        resource={
            'package_id': package_polygons['id'],
            'name': 'Polygons Data',
            'format': 'GEOJSON',
            'is_preview': 'true'
        },
        fields=get_fields(polygons),
        records=polygons.to_dict('records')
    )

    print('Sample maps package (polygons) successfully created and populated with resource')
