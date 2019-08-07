if (window.location.host.indexOf('intra') !== -1) {
    var ckan = window.location.host.replace('odadmin', 'ckanadmin');
} else if (window.location.host.indexOf('inter') !== -1) {
    var ckan = window.location.host.replace('portal', 'ckan');
} else {
    var ckan = 'ckan0.cf.opendata.inter.prod-toronto.ca'
}

var config = { 'ckanAPI': 'http://localhost:5000' + '/api/3/action/', 'ckanURL': 'http://localhost:5000' }