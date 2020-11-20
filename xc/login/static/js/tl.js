
var tl = tl || {}

tl.stringtable = {}
tl.curlang = 'en'
tl.invtable = {}
tl.alltable = {}

tl.getCurrentLanguage = function() {
    var res = tl.curlang
    if (document.forms.xc_langselect != undefined) {
	res = document.forms.xc_langselect.lang.value
    }
    return res
}

tl.setCurrentLanguage = function(lang) {
    tl.curlang = lang
    if (document.forms.xc_langselect != undefined) {
	document.forms.xc_langselect.lang.value = lang
    }
    document.documentElement.setAttribute('lang', lang)
    tl.update()
}

tl.updateDict = function() {
    tl.invtable = {}
    Object.keys(tl.stringtable).forEach((k) => {
	tl.invtable[tl.stringtable[k]['en']] = k
    })
    tl.alltable = {}
    Object.keys(tl.stringtable).forEach((k) => {
	var ent = tl.stringtable[k]
	Object.keys(ent).forEach((j) => {
	    tl.alltable[ent[j]] = k
	})
    })
}

tl.apptable = function(data) {
    tl.stringtable = Object.assign({}, tl.stringtable, data)
    tl.updateDict()
}

tl.settable = function(data) {
    tl.stringtable = data
    tl.updateDict()
}

tl.get = function(id) {
    var str = ''
    if (id in tl.stringtable) {
	var entry = tl.stringtable[id]
	var cl = tl.getCurrentLanguage()
	str = entry[cl]
	return str
    }
    console.error('tl: cannot find string for "' + id + '"')
    return str
}

tl.strelem = function(key, str) {
    return '<span class="tlg" data-tid="' + key + '">' + str + '</span>'
}

tl.tlelem = function(str) {
    return '<span class="tlt">' + str + '</span>'
}

tl.transl = function(str) {
    var cl = tl.getCurrentLanguage()
    if (str in tl.invtable) {
	var key = tl.invtable[str]
	return tl.get(key)
    }
    console.error('tl: cannot find translation for "' + str + '"')
    return str
}

tl.itransl = function(str) {
    if (str in tl.alltable) {
	var key = tl.alltable[str]
	return tl.stringtable[key]['en']
    }
    console.error('tl: cannot find inverse translation for "' + str + '"')
    return str
}

tl.deftable = {
    lang: {en: 'Language', de: 'Sprache'}
}

tl.apptable(tl.deftable)

//console.log(tl.get('lang'))

tl.update = function() {
    var elems = document.querySelectorAll('.tlt')
    elems.forEach((k) => {
	if (k.dataset.tdone != '1') {
	    k.dataset.tdone = '1'
	    k.innerHTML = tl.transl(k.innerHTML)
	}
    })
    elems = document.querySelectorAll('.tlg')
    elems.forEach((k) => {
	if (k.dataset.tdone != '1') {
	    k.dataset.tdone = '1'
	    k.innerHTML = tl.get(k.dataset.tid)
	}
    })
    elems = document.querySelectorAll('.tltv')
    elems.forEach((k) => {
	if (k.dataset.tdone != '1') {
	    k.dataset.tdone = '1'
	    k.value = tl.transl(k.value)
	}
    })
    elems = document.querySelectorAll('.tlto')
    elems.forEach((k) => {
	if (k.dataset.tdone != '1') {
	    k.dataset.tdone = '1'
	    k.innerText = tl.transl(k.innerText)
	}
    })
    elems = document.querySelectorAll('.tln')
    elems.forEach((k) => {
	if (k.dataset.tdone != '1') {
	    k.dataset.tdone = '1'
	    var n = Number(k.innerText)
	    if (n + '' != 'NaN') {
		k.innerText = n.toLocaleString(undefined, {useGrouping: false})
	    }
	}
    })
    elems = document.querySelectorAll('.tlnv')
    elems.forEach((k) => {
	if (k.dataset.tndone != '1') {
	    k.dataset.tndone = '1'
	    var n = Number(k.value)
	    if (n + '' != 'NaN') {
		var s = n.toLocaleString(undefined, {useGrouping: false})
		k.setAttribute('value', s)
	    }
	}
    })
}
