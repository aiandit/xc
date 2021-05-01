var xc = {}

xc.docs = {}
xc.curtype = 'xc'

if (typeof xframe == "undefined") {
    xframe = 'index'
}

var frames = [
    {target: 'content',
     xlp: xlp.mkXLP(['xc.xsl'], '/static/xsl/')},
    {target: 'title',
     xlp: xlp.mkXLP(['xc-title.xsl'], '/static/xsl/', {output: 'text'})}
]

var myframes = xframes.mkXframes(frames, '/static/xsl/')

var unescapeXML = function(x) {
    return x.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&')
}

var extractXPath_XPath = function(doc, xpath, toDoc, wrap, done) {
    var rtype = toDoc ? XPathResult.UNORDERED_NODE_ITERATOR_TYPE : XPathResult.STRING_TYPE
    var r = doc.evaluate(xpath, doc, null, rtype, null)
    var n = toDoc ? r.iterateNext() : unescapeXML(r.stringValue)
    done(n)
    // want a document as result...
}

var extractXPath = function(doc, xpath, toDoc, wrap, done) {
    var output = toDoc ? 'xml' : 'text'
    var indoc = '<x><xpath-expr>' + xpath + '</xpath-expr><output>' + output + '</output><wrap>' + wrap + '</wrap></x>'
    var filters = ['gen-get-xpath.xsl']
    if (xlp.isMozilla) {
        filters = ['gen-get-xpath.xsl', 'patch-ns.xsl']
    }
    var genxsl = xlp.mkXLP(filters, xframes.spath('xsl/'))
    genxsl.transform(indoc, function(gxsl) {
        var seltrans = xlp.mkXLP([gxsl], '')
        seltrans.transform(doc, toDoc, function(result) {
            if (xlp.isMozilla) {
                if (!toDoc) {
                    result.textContent = unescapeXML(result.textContent)
                }
            }
            done(result)
        })
    })
}

var getActionLSL = function(cname, done) {
    var classes = ['filters',
                   'pipelines',
                   'constructor-filters',
                   'constructor-pipelines',
                   'types'
                  ]
    var URLs = ['/main/ajax_find?findsys=1&find=' + cname + '-*.xsl',
                '/main/ajax_find?findsys=1&findpath=1&find=*/pipelines/' + cname + '-*.xml',
                '/main/ajax_find?findsys=1&find=create-*.xsl',
                '/main/ajax_find?findsys=1&findpath=1&find=*/pipelines/create-*.xml',
                '/main/ajax_find?findsys=1&findpath=1&find=*/types/*.xml'
               ]
    xlp.mloadXML(URLs, function(results) {
        xlp.amap(results, function(res, done) {
            extractXPath(res, '/*/dict/data/findlist', true, '', function(ressel) {
                done(ressel.documentElement.outerHTML)
            })
        }, function(findlists) {
            findlists = Object.keys(findlists).map(function(k) {
                return xc.getXDoc(findlists[k], classes[k])
            })
            var findlists = findlists.join('\n')
            console.log('action findlist XML: ' + findlists)
            done(0, findlists)
        })
    })
}

xc.xslpath = '/main/getf/'

xc.isXC = function(dclass) {
    return !(dclass == 'svg' || dclass == 'html')
}

xc.classViewFunctions = {}
xc.mkClassViewFunction = function(targetid, dclass, mode, done) {
    var transformName = dclass + '-' + mode

    var frames = [
        {target: targetid + '-title',
         xlp: xlp.mkXLP(['xc-app-title.xsl'], '/main/getf/xsl/', {output: 'text'})},
        {target: targetid + '-document',
         xlp: xlp.mkXLP(['pipelines/' + transformName + '.xml'], '/main/getf/')},
        {target: targetid + '-document-actions',
         xlp: xlp.mkXLP(['docactions-html.xsl'], '/main/getf/xsl/')},
        {target: targetid + '-document-info',
         xlp: xlp.mkXLP(['xc-document-info.xsl', 'docinfo-html.xsl'], '/main/getf/xsl/')}
    ]
    var sframes = xframes.mkXframes(frames, xc.xslpath)

    var parameters = xc.curresp.getElementsByTagName('cgi')[0].outerHTML
    var infoxml = '<viewclass>' + dclass + '</viewclass>'
    infoxml += '<viewmode>' + mode + '</viewmode>'
    infoxml += '<targetid>' + targetid + '</targetid>'
    var lsls = xc.curresp.getElementsByTagName('lsl')
    if (lsls.length > 0) {
        infoxml += lsls[0].outerHTML
    }

    var res = {
        render: function(xcontdoc, done, preprocess) {

            var linfoxml = infoxml

            var parameters = xc.curresp.getElementsByTagName('cgi')[0].outerHTML
            linfoxml += '<parameters>' + parameters + '</parameters>'

            try {
                var userinfo = xc.curresp.getElementsByTagName('user')[0].outerHTML
                linfoxml += userinfo
            } catch {
            }

            var indoc = xc.getCurDoc(xcontdoc, xc.cgiParams() + linfoxml)

            sframes.render(indoc, function(res) {
                console.log('Class render complete')
                xlp.amap(frames, (k, done) => {
                    var n = document.getElementById(k.target)
                    if (n) {
                        updateTree2(n)
                    }
                    done(n)
                }, function(res) {
                    console.log('Class render fully complete')
                    updateTree2(document)
                    done(res)
                })
            }, function(res, pdone) {
                console.log('Class generation complete')
                preprocess(res, pdone)
            })

        }
    }

    done(res)
}

xc.getClassViewFunction = function(targetid, dclass, mode, done) {
    var verb = 'view'
    var vparam = xc.curresp.querySelector('cgi > v')
    if (vparam != null) {
	verb = vparam.textContent
    } else {
        vparam = xc.cursubresp.querySelector('dict > view')
        if (vparam != null) {
	    verb = vparam.textContent
        } else {
            vparam = xc.curresp.querySelector('dict > view')
            if (vparam != null) {
	        verb = vparam.textContent
            }
        }
        if (verb != 'edit') {
            verb = 'view'
        }
    }
    dclass += '-' + verb
    var key = targetid + '-' + dclass + '-' + mode
    var incache = xc.classViewFunctions[key]
    if (typeof incache == 'undefined') {
        xc.mkClassViewFunction(targetid, dclass, mode, function(res) {
            incache = res
            xc.classViewFunctions[key] = res
            done(res)
        })
    } else {
        done(incache)
    }
}

var updateXView = function(ev) {
    updateXDataView(ev, function() {
        console.log('XView render by event ' + ev + ' complete')
    })
}

xc.autoRender = function(ev, xcontdoc, targetid, done) {

    var xinfo = xlp.mkXLP(['xc-info-json.xsl'], xc.xslpath)
    xinfo.transform(xcontdoc, false, function(jinfo) {
        var dclass = 'default'
        if (! jinfo) {
            console.error('XC: failed to get doc class info in JSON format')
        } else {
            var info = JSON.parse(jinfo.textContent)
            if (info.class.length>0) {
		dclass = info.class
            } else {
		console.error('XC: No Xdata class found in the JSON structure')
            }
        }
        var mode = 'html'
        var modeForm = document.forms['xc-control']
        if (modeForm) {
	    mode = modeForm.elements['mode'].value
        }
	console.log('XC: class is ' + dclass)
	xc.docs[dclass] = xcontdoc
        xc.getClassViewFunction(targetid, dclass, mode, function(viewFun) {
	    viewFun.render(xcontdoc, function(res) {
                console.log('Done with autoRender cycle ' + targetid)
                done(res)
	    }, function(res, pdone) {
                console.log('Before insert in autoRender cycle ' + targetid)
                updateTreeFinal(res, ev, pdone)
	    })
        })
    })

}

var updateXDataView = function(ev, done) {

    var xcontdoc = xc.getCurDocText(xc.curdoc)
    var mode = 'html'

    var editForm = document.forms['xc-form-edit']
    if (editForm) {
        editForm.data.value = xcontdoc
    }

    if (!xcontdoc.startsWith('<')) {
        console.log('No XML data')
        xcontdoc = xc.getXDoc('', 'xc')
    }

    xc.autoRender(ev, xcontdoc, 'xc', function(res) {
        console.log('main render cycle done')
        done(res)
    })

}

var getXDataXML = function(inxml) {
    var doc = null
    var indoc = xlp.parseXMLC(inxml)
    if (indoc != undefined) {
        doc = indoc
    } else {
        var firstTag = inxml.match(/<[a-zA-Z0-9-_]+/)
        var rootnode = null
        if (firstTag == null || firstTag.length == 0) {
        } else {
            rootnode = firstTag[0].substr(1) + 's'
        }
	if (rootnode != null) {
            indoc = xlp.parseXMLC(xc.getXDoc(inxml, rootnode))
            if (indoc != undefined) {
		doc = indoc
            }
	}
    }
    return doc
}

var getXData = function(ev, request, done) {
    extractXPath(request.responseXML, '/*/xcontent', true, '', function(xcontdoc) {
        if (xcontdoc.nodeType == xcontdoc.DOCUMENT_NODE && xcontdoc.childElementCount > 0
            && xcontdoc.documentElement.childElementCount >= 1) {
            if (xcontdoc.documentElement.childElementCount == 1) {
                extractXPath(request.responseXML, '/*/xcontent/*', true, '', function(xcontdoc) {
                    done(xcontdoc)
                })
            } else {
                done(xlp.parseXML(xc.getXDoc(xcontdoc.documentElement.innerHTML,
                                                xcontdoc.documentElement.firstElementChild.nodeName + 's')))
            }
        } else {
	    var mimetype = xlp.xPath_selectString(request.responseXML, '/*/xcontent-cdata/@mime-type')
            extractXPath(request.responseXML, '/*/xcontent-cdata/text()', false, '', function(xcontdoc) {
                if (xcontdoc.nodeType == xcontdoc.DOCUMENT_FRAGMENT_NODE) {
		    if (mimetype.length > 0) {
                        done(xcontdoc, mimetype)
		    } else {
                        var xmldata = xcontdoc.textContent
			var indoc = null
                        if (xmldata.length > 0) {
			    indoc = getXDataXML(xmldata)
                        }
			if (indoc != null) {
                            done(indoc)
			} else {
                            done(request.responseXML)
			}
		    }
                }
            })
        }
    })
}

var processXData = function(ev, request, done) {
    xc.cursubresp = xc.curresp = request.responseXML
    getXData(ev, request, function(xcontdoc, mimetype) {
        if (xcontdoc.nodeType == xcontdoc.DOCUMENT_NODE) {
            xc.curdoc = xcontdoc
        } else if (xcontdoc.nodeType == xcontdoc.DOCUMENT_FRAGMENT_NODE) {
            if (mimetype == 'application/xml') {
                try {
                    var xdoc = xlp.parseXML(xcontdoc.textContent)
                    xcontdoc = xdoc
                } catch {
                }
            }
            xc.curdoc = xcontdoc
	    xc.curtype = mimetype
        } else {
            xc.curdoc = xc.getXDoc('<x>no valid data</x>')
        }
        updateXDataView(ev, function(res) {
            done(res)
        })
    })
}

xc.handleLinkClickA = function(ev, elem) {
    document.querySelectorAll('.xc-active-link').forEach((e) => {
	e.classList.remove('xc-active-link')
    })
    elem.classList.add('xc-active-link')
    if (elem.href.startsWith('javascript:')) {
        return true;
    } else {
	xc.clearIntervals();
        // console.log('A: redirect to ajax source: ' + xframes.ajaxPathName(ev.target.href))
        myframes.renderLink(elem, xframes.ajaxPathName(elem.href), function(request) {
            renderPostProc(ev, request)
        })
        return false
    }
}

var handleLinkClick = function(ev, target) {
    if (!target) {
        target = ev.target
    }
    while(target.nodeName != 'A' && !target.nodeName.startsWith('#')) {
	target = target.parentElement
    }
    return xc.handleLinkClickA(ev, target)
}

var dohandleFormSubmit = function(form, ev) {
    console.log('Form ' + form.name + ' has been submitted')
    // console.log(form)
    // console.log(form.action)
    if (form.attributes.action == undefined || form.attributes.action.value.length == 0) {
        return true
    } else if (form.action.startsWith('javascript:')) {
        var this_ = form
        var evres = eval(form.action.substr(11))
        console.log(evres)
        var res = evres(ev)
        return false
    } else {
	xc.clearIntervals();
        myframes.renderFormSubmit(form, xframes.ajaxPathName(form.action), function(request) {
            // console.log('A form POST submit is handled completely')
            renderPostProc(ev, request)
        })
        return false
    }
}
var handleFormSubmit = function(ev) {
    return dohandleFormSubmit(ev.target, ev)
}

var runxc = function(x, ev) {
    console.log('run: x ' + x)
    console.log('run: ev ' + ev)

    console.log('run: xframe ' + xframe)

    var paramss = ''
    if (xframes.cgij.length > 0) {
        var params = JSON.parse(xframes.cgij)
        for (k in params) {
            paramss += '&' + k + '=' + params[k]
        }
        paramss = '?' + paramss.substr(1)
    }

    var ajaxurl = '/' + xframe_xapp + '/ajax_' + xframe_view + paramss

    console.log('run: ajax URL ' + ajaxurl)

    myframes.renderLink(document, ajaxurl, function(res) {
        console.log('done xerp load')
        renderPostProc(ev, res)
    })

    window.addEventListener("popstate", function (event) {
        console.log('popstate: ' + event.state)
	if (event.state != null) {
	    myframes.renderLink(document, xframes.ajaxPathName(event.state), function(res) {
		renderPostProc(event, res)
	    })
	}
    })
    window.addEventListener( "pageshow", function ( event ) {
//        console.log('pageshow')
//        window.location = event.state
    })

    return false
}

var renderPostProc = function(ev, request, subreq) {
    console.log('render: ' + request)
    if (subreq == undefined) {
	xframes.pushhist(request)
    }
    if (!isNonXMLResponse(request)) {
        processXData(ev, request, function() {
            console.log('processXData done')
        })
    } else {
        console.error('Got non XML response')
    }
}

var setFormCallback = function(subtree, handle) {
    var forms = subtree.querySelectorAll('form')
    var ffunc = function(ev) {
        console.log(name + ': form submit  event for: ' + ev);
	xc.clearIntervals();
        var res = handle(ev)
        console.log(name + ': form submit  event returned: ' + res);
        return res
    }
//    console.log(name + ': ' + forms.length + ' forms found');
    for (var k=0; k < forms.length; ++k) {
//        console.log(name + ': set form submit event for: ' + forms[k].id);
        forms[k].onsubmit = ffunc;
        if (forms[k].elements.csrfmiddlewaretoken == undefined) {
            forms[k].innerHTML += "<input type='hidden' name='csrfmiddlewaretoken' value=''/>"
        }
    }
}

var setLinkCallback = function(subtree, handle) {
    var forms = subtree.querySelectorAll('a')
    var ffunc = function(ev, x) {
        if (!x) {
            x = ev.target
        }
        console.log('link click event for: ' + ev + ' on ' + x);
        if (x.classList.contains('xc-nocatch')) return true
        if ((new URL(x.href)).host != xlp.gethost()) return true
        var res = handle(ev, x)
        console.log(name + ': link click event handler returned: ' + res);
        return res
    }
    Object.keys(forms).forEach(function(k) {
        var oldHandler = forms[k].onclick
        forms[k].onclick = function(x, y) {
            return ffunc(x, y)
        }
    })
}

xc.intervals = {}
xc.setInterval = function(key, inter) {
    xc.intervals[key] = inter
}
xc.clearInterval = function(key) {
    if (key in xc.intervals) {
	clearInterval(xc.intervals[key])
	delete xc.intervals[key]
    }
}
xc.cintervals = {}
xc.setChainedInterval = function(key, inter) {
    xc.cintervals[key] = true
}
xc.clearChainedInterval = function(key) {
    if (key in xc.cintervals) {
	delete xc.cintervals[key]
    }
}
xc.isChainedInterval = function(key) {
    if (key in xc.cintervals) {
	return true
    }
    return false
}
xc.stop = xc.clearIntervals = function() {
    Object.keys(xc.intervals).forEach(function(k) {
	xc.clearInterval(k)
    })
    Object.keys(xc.cintervals).forEach(function(k) {
	xc.clearChainedInterval(k)
    })
}

var psMultiField = function(data) {
    if (data.length == 0) return ''
    var items = data.split('\n')[1].split(' ')
    items = items.filter( (k) => k.length > 0 )
    return '<td>' + items.join('</td><td>') + '</td>'
}
xc.psHTMLC = function(data, done) {
    done(xc.psHTML(data))
}
xc.psHTML = function(data) {
    if (data.length == 0) return ''
    return data
}
xc.psHead = function(n) {
    return function(data) {
	var lines = data.split('\n')
	return lines.slice(0, n).join('\n')
    }
}
var psSingleField = function(data) {
    if (data.length == 0) return ''
    return '<span>' + data.split('\n')[1] + '</span>'
}
var psText = function(data) {
    return '<span>' + data + '</span>'
}

xc.getCSRFToken = function() {
    var csrf = ''
    Object.keys(document.forms).forEach(function(k) {
	var csrfv = ''
	if (document.forms[k].csrfmiddlewaretoken != undefined) {
	    csrfv = document.forms[k].csrfmiddlewaretoken.value
	}
	if (csrfv != '' && csrf == '') {
	    csrf = document.forms[k].csrfmiddlewaretoken.value
	}
    })
    return csrf
}

//var globtO =  (new Date()).getTime()
xc.polls = {}
var ppPolls = function(subtree, ev, done) {
    var tms = subtree.querySelectorAll('.xc-sl-poll')

    var doPoll = function(el, eldone) {
        var myid = (new Date()).getTime() + '' + el.dataset.pollUrl
        xc.polls[myid] = 1

	var getf = function(ciid, count) {
	    el = document.getElementById(ciid)
	    if (!xc.isChainedInterval(ciid)) {
//		console.log('Chained interval ' + ciid + ' was cancelled')
		return
	    }
	    var url = el.dataset.pollUrl
	    var t0 = (new Date()).getTime()
//	    console.log('getf: ' + (t0 - globtO) + ': '  + url)
	    var ppFun = eval(el.dataset.postprocess)
            var finalStep = function(res) {
		var nexttime = el.dataset.pollInterval - (new Date()).getTime() + t0 - 1
		setTimeout(getf, nexttime, ciid, count+1, t0)
		if (count == 0) {

                    var tn = document.getElementById(el.dataset.pollTarget + '-document')
                    tn.onclick = function(ev) {
                        if (ev.target.nodeName != 'SELECT'
                            && ev.target.nodeName != 'OPTION'
                            && ev.target.nodeName != 'INPUT'
                            && ev.target.nodeName != 'A') {
	                    getf(ciid, 1)
                        }
                    }
                    tn.dataset.pollId = ciid
                    tn.classList.add('xc-sl-poll-target')
                    xc.polls[myid] = 0
                    eldone(res)

		}
            }
	    var handleData = function(text) {
		var res
                if (ppFun != undefined) {
		    try {
		        res = ppFun(text, el)
		    } catch (error) {
		        console.error('ppPolls catched error in user function ' + el.dataset.postprocess);
		        console.error(error);
		        res = {noupdate: true}
		    }
		    if (typeof res == typeof {}) {
		        if (!res.noupdate) {
			    el.innerHTML = res.text
		        }
		        if (typeof res.done == 'function') {
			    res.done()
		        }
		    } else {
		        el.innerHTML = res
		    }
		    updateTreeFinal(el, undefined, function(utres) {
                        finalStep(res)
		    })
                } else {
                    xc.autoRender(ev, text, el.dataset.pollTarget, function(res) {
                        console.log('poll auto render done')
                        finalStep(res)
                    })
                }
	    }
            var splitFirst = function(s, c) {
                var i = s.indexOf(c)
                if (i >= 0) {
                    return [s.substr(0, i), s.substr(i+1)]
                }
                return [s]
            }
	    var handleResult = function(st, res) {
		if (st == 0) {
		    if (res.responseXML != undefined) {
			extractXPath(res.responseXML, '/*/xcontent-cdata', false, '', function(x) {
			    if (x.textContent.length > 0) {
				handleData(x.textContent)
			    } else {
				handleData(res.responseXML)
			    }
			})
		    } else {
                        if (el.dataset.pollWrap != undefined) {
                            var headers = res.getAllResponseHeaders()
                            headers = headers.split('\n')
                            headers = headers.filter((k)=>k.length>0)
                            headers = headers.map((k)=>splitFirst(k, ':'))
                            var hdict = {}
                            for (var i = 0; i < headers.length; ++i) {
                                hdict[headers[i][0]] = headers[i][1].trim()
                            }
                            var lineinfo = xc.dictXML(hdict)
                            var xdoc = xlp.mkdoc(xc.getXDoc(
                                xc.getXDoc(res.responseText, 'lines')
                                    + '<headers>' + lineinfo + '</headers>', el.dataset.pollWrap))
                            xc.cursubresp = xdoc
                            handleData(xdoc)
                        } else {
			    handleData(res.responseText)
                        }
		    }
		} else {
                    xlp.error('Failed to poll ' + url)
                }
	    }
	    var method = el.dataset.pollMethod || 'get'
	    if (method.toLowerCase() == 'post') {
		var parts = url.split('?')
		var rdata = parts[1] + '&csrfmiddlewaretoken=' + xc.getCSRFToken()
		var headers = {'Content-type': 'application/x-www-form-urlencoded'}
		xlp.sendPost(parts[0], rdata, headers, handleResult)
	    } else {
		xlp.sendGet(url, handleResult)
	    }
	}
	if (el.attributes.id == undefined) {
	    el.setAttribute('id', 'pid' + String((new Date()).getTime()))
	}
	var pollid = el.attributes.id.value
	if (el.dataset.pollRunning == undefined) {
	    el.dataset.pollRunning = true
	    xc.setChainedInterval(pollid)
	    getf(pollid, 0, (new Date()).getTime())
	}
    }

    xlp.amap(tms, doPoll, function(res) {
	if (tms.length > 0) {
	    console.log('All polls done')
	}
	done(res)
    })

}

xc.id = function() {
    return '' + (new Date()).getTime()
}

xc.views = {}
var ppViews = function(subtree, ev, done) {
    var tms = subtree.querySelectorAll('.xc-sl-view')
    var doView = function(el, eldone) {
        var myid = (new Date()).getTime() + '' + el.dataset.viewUrl
        xc.views[myid] = 1
	var getf = function() {
            var viewFilter = el.dataset.viewFilter || 'auto'
            var viewTarget = el.dataset.viewTarget
	    var viewName = el.dataset.viewName || 'unknown-view'
	    var viewWrap = el.dataset.viewWrap
	    var viewMode = el.dataset.viewMode || 'xml'
	    var viewCache = el.dataset.viewCache || false
	    var url = el.dataset.viewUrl
            var lastStep = function(request) {
		xc.docs[viewName] = request.responseXML
	        var onloadCode = el.dataset.viewOnload
	        eval(onloadCode)
	        console.log('VIEW: sub view ' + url + ' is handled completely')
                xc.views[myid] = 0
	        eldone(request)
            }
            if (viewFilter == 'auto') {
                var lfun = viewCache ? xlp.loadCached : (viewMode == 'xml' ? xlp.loadXML : xlp.loadText)
                lfun(url, function(dt) {
                    if (viewWrap) {
                        dt = xc.getXDoc(dt, viewWrap)
                    }
                    xc.cursubresp = xlp.mkdoc(dt)
                    xc.autoRender(ev, dt, viewTarget, lastStep)
                })
            } else {
	        var localframes = [
		    {target: viewTarget,
		     filters: [ viewFilter ]}
	        ]
	        var mylframes = xframes.mkXframes(localframes, xc.xslpath)
                mylframes.renderLink(ev.target, xframes.ajaxPathName(xlp.getbase() + url), function(request) {
		    updateTreeFinal(document.querySelector('#' + el.dataset.viewTarget), ev, lastStep)
                }, viewCache)
            }
	    el.dataset.viewDone = '1'
	}
	if (el.dataset.viewDone != '1') {
            if (el.attributes.id == undefined) {
                const nid = xc.id()
                el.setAttribute('id', nid + '-document')
                el.setAttribute('data-view-target', nid)
            }
	    getf()
	} else {
            eldone()
        }
        return false
    }
    xlp.amap(tms, doView, function(res) {
	if (tms.length > 0) {
	    console.log('All views done')
	}
	done(res)
    })
}

var ppActions = function(subtree, ev) {
    var tms = subtree.querySelectorAll('.xc-action')
    tms.forEach(function(el) {
	var getf = function() {
	    var actionCode = el.dataset.action
	    var res = eval(actionCode)
	    el.dataset.actionResult = res
	}
	if (el.dataset.actionDone != '1') {
	    el.dataset.actionDone = 1
	    getf()
	}
    })
}

var ppTimestamps = function(subtree) {
    var tms = subtree.querySelectorAll('span.unixtm')
    tms.forEach(function(el) {
        if (el.dataset.unixtm != 1) {
            var flval = Number(el.innerHTML)
            var d = new Date(flval*1000)
            var sd = d.toISOString()
            var ts = d.toLocaleTimeString()

            el.innerHTML = '<span title="' + d + '">' + sd.substr(0, 10) + ' ' + ts + '</span>'
            el.dataset.unixtm = 1
            el.dataset.flval = flval
        }
    })
}

var ppMarkup = function(subtree) {
    var tms = subtree.querySelectorAll('.markup')
    tms.forEach(function(el) {
        if (el.dataset.markupDone != 1) {
            el.dataset.markupDone = 1
            el.innerHTML = el.innerText
        }
    })
}

var displayNumber = function(str) {
    return String(str).replace('.', ',')
}

var ppUnits = function(subtree) {
    var tms = subtree.querySelectorAll('span.value-with-unit')
    tms.forEach(function(el) {
        if (el.dataset.unit != el.dataset.targetunit) {
            if (el.dataset.targetunit == undefined) {
                if (el.dataset.unit == 'B') {
                    el.dataset.targetunit = 'KB'
                }
            }
//            console.log('GG: ' + el.innerHTML)
            var flval = Number(el.firstElementChild.innerText)
            if (el.dataset.unit == 'B' && el.dataset.targetunit == 'KB') {
                el.innerHTML = '<span title="' + flval + el.dataset.unit + '">'
                    + displayNumber((Math.ceil(100*flval/1024)/100).toFixed(2)) + '</span>'
            } else if (el.dataset.unit == 'B' && el.dataset.targetunit == 'MB') {
                el.innerHTML = '<span title="' + flval + el.dataset.unit + '">'
                    + displayNumber((Math.ceil(100*flval/(1024*1024))/100).toFixed(2)) + '</span>'
            }
	    el.innerHTML +=  '<span>' + '&#xa0;' + el.dataset.targetunit + '</span>'
            el.dataset.unit = el.dataset.targetunit
            el.dataset.flval = flval
        }
    })
    var tms = subtree.querySelectorAll('span.number')
    tms.forEach(function(el) {
        var flval = el.innerHTML
        el.innerHTML = '<span title="' + flval + '">' + displayNumber(flval) + '</span>'
    })
}

var ppSliders = function(subtree) {
    var tms = subtree.querySelectorAll('.xc-slider')
    tms.forEach(function(el) {
	var rin = el.querySelector('[type="range"]')
	var tin = el.querySelector('[type="text"]')
	rin.onchange = rin.oninput = function(x, ev) {
	    tin.value = rin.value
	}
	tin.onchange = tin.oninput = function(x, ev) {
	    rin.value = tin.value
	}
    })
}

xc.setButtonLinkHandlers = function(subtree) {
    var tms = subtree.querySelectorAll('.xc-blink')
    tms.forEach(function(el) {
	var bonclick = function(ev) {
	    var a = ev.target.querySelector('a')
	    if (a != null) {
		return xc.handleLinkClickA(ev, a)
	    }
	    return true
	}
	if (el.dataset.linkHandlerSet == undefined) {
	    el.onclick = bonclick
	    el.dataset.linkHandlerSet = true
	}
    })
}

xc.dictXML = function(data, exclude) {
    var rdict = {}
    Object.keys(data).forEach(function(k) {
//        if (exclude && k in exclude) return
        var r = '<' + k + '>' + data[k] + '</' + k + '>'
        rdict[k] = r
    })
    return Object.values(rdict).join('\n')
}

xc.getCGIXML = function(form, exclude) {
    if (exclude == undefined) {
        exclude = {data:1}
    }
    var cgiData = xlp.mkFormDataDict(form)
    // console.log(cgiData)
    var cgixml = {}
    Object.keys(cgiData).forEach(function(k) {
        if (k in exclude) return
        var r = '<' + k + '>' + cgiData[k] + '</' + k + '>\n'
        // console.log(k)
        // console.log(r)
        cgixml[k] = r
    })
    // console.log(cgixml)
    return xc.getXDoc(Object.values(cgixml).join(''), 'cgi')
}

xc.cgiParams = function(ev, exclude) {
    if (exclude == undefined) {
        exclude = {data:1}
    }
    var res = Object.keys(document.forms).map(function(k) {
        var f = document.forms[k]
        return '<cgi>' + xc.getCGIXML(f) + '</cgi>'
    })
    return res.join('\n')
}

xc.createElement = function(ev, name) {
    var frames = [
        {target: 'xc-document',
         filters: [
             'create-' + name + '.xsl'
         ]}
    ]
    var sframes = xframes.mkXframes(frames, '/main/ajax_runwhich?action=get&submit=1&which=*/xsl/')
    var inxml = '<x>' + xc.cgiParams() + '</x>'
    console.log(inxml)
    var indoc = xlp.parseXML(inxml)
    sframes.render(indoc, function(res) {
        console.log('Done with xc.createElement ' + name)
        updateTree(document, ev)
    })
}

xc.getXDoc = function(xcontdoc, nodename) {
    return '<' + nodename + ' xmlns="http://ai-and-it.de/xmlns/2020/xc">' + xcontdoc + '</' + nodename + '>'
}

xc.getDocText = function(xcontdoc) {
    var xcont = ''
    if (xcontdoc.documentElement != undefined) {
        xcont = xcontdoc.documentElement.outerHTML
    } else if (xcontdoc.textContent != undefined) {
        xcont = xcontdoc.textContent
    }
    return xcont
}
xc.getCurDocText = function(xcontdoc) {
    var xcont = ''
    if (xcontdoc != undefined) {
        xcont = xc.getDocText(xcontdoc)
    }
    return xcont
}

xc.getCurDoc = function(xcontdoc, infoxml) {
    if (infoxml == undefined) {
        infoxml = ''
    }
    var xcont = typeof xcontdoc == "string" ? xcontdoc : xc.getCurDocText(xcontdoc)
    var indoc = xc.getXDoc('<cont>' + xcont + '</cont>' + infoxml, 'x')
    return indoc
}

xc.performAction = function(ev, name) {
    var filters = [ name, 'xc-cleanup.xsl', 'xc-pretty.xsl' ]
    var inxml = xc.getXDoc(xc.cgiParams() + '<cont>' +
                           xc.getCurDocText(xc.curdoc) + '</cont>', 'x')
    var genxsl = xlp.mkXLP(filters, xc.xslpath)
    genxsl.transform(inxml, function(res) {
        xc.curdoc = res
        console.log('Done with performAction ' + name)
        updateXDataView(ev, function(res) {
            console.log('Perform action complete')
        })
    })
}

xc.loadXML = function(path, done) {
    xlp.loadXML('/main/getf/' + path, function(st, resp) {
        done(resp.responseXML)
    })
}

xc.createDoctype = function(ev, name) {
    var filters = [ 'xc-cleanup.xsl', 'xc-pretty.xsl' ]
    var genxsl = xlp.mkXLP(filters, xc.xslpath)
    xlp.loadXML('/main/getf' + name, function(dt) {
        var inxml = xc.getXDoc(xc.cgiParams() + '<cont>' +
                                  dt.documentElement.outerHTML + '</cont>', 'x')
        genxsl.transform(inxml, function(res) {
            xc.curdoc = res
            console.log('Done with performAction ' + name)
            updateXDataView(ev, function(res) {
                console.log('Perform action complete')
            })
        })
    })
}

var xcRender = function(done) {
    var frames = [
        {target: 'xc-controls',
         filters: [
             'xc-generate.xsl'
         ]}
    ]
    var sframes = xframes.mkXframes(frames, xframes.spath('xsl/'))
    sframes.render(xc.curdoc, function(res) {
        console.log('Done with xc render')
        console.log(res)
        done(status, res)
    })
}

var updateTree = function(subtree, ev) {
    setFormCallback(subtree, handleFormSubmit)
    setLinkCallback(subtree, handleLinkClick)

    var forms = subtree.querySelectorAll('.oc-head')
    Object.keys(forms).forEach(function(k) {
        var f = forms[k]
        var t = f.nextElementSibling
        var iso = t.classList.contains('oc-open')
        f.onclick = function() {
            if (t.style.visibility == 'visible' || (t.style.visibility == "" && iso)) {
                t.style.visibility = 'hidden'
                t.style.display = 'none'
            } else {
                t.style.visibility = 'visible'
                t.style.display = t.dataset.display || 'block'
            }
        }
    })

    ppMarkup(subtree)
    ppTimestamps(subtree)
    ppUnits(subtree)
    ppSliders(subtree)
    xc.setButtonLinkHandlers(subtree)
//    document.forms[0].scrollIntoView()

    if (xc.registeredHandles['tree1']) {
        xc.registeredHandles['tree1'].forEach(function(handle) {
            handle(subtree)
        })
    }
}

var updateTree2 = function(subtree, ev) {
    updateTree(subtree, ev)
    ppActions(subtree, ev)
    tl.update(subtree)
    ppSorts(subtree, ev)
    xc.ppActiveLink(subtree, ev)
    if (xc.registeredHandles['tree2']) {
        xc.registeredHandles['tree2'].forEach(function(handle) {
            handle(subtree)
        })
    }
}

var updateTreeFinal = function(subtree, ev, done) {
    updateTree2(subtree, ev)
    ppPolls(subtree, ev, function(result) {
	ppViews(subtree, ev, function(result) {

            if (xc.registeredHandles['tree3']) {
                xlp.amap(xc.registeredHandles['tree3'],
                         function(handle, eldone) {
                             handle(subtree, eldone)
                         },
                         done)
            } else {
                done(result)
            }

	})
    })
}

var isNonXMLResponse = function(request) {
    return (request.responseXML === null
            || request.responseXML.documentElement === null)
}

var isErrorResponse = function(request) {
    return (isNonXMLResponse(request)
            || request.responseXML.documentElement.nodeName == "xc")
}

xc.csv2xml = function(text) {
    var lines = text.split('\n')
    lines = lines.map(function(l) {
	var items = l.split(';')
	return '<td>' + items.join('</td><td>') + '</td>'
    })
    return '<table xmlns="http://www.w3.org/1999/xhtml"><tr>' + lines.join('</tr><tr>') + '</tr></table>'
}

xc.readCSV = function(text) {
    var lines = text.split('\n')
    var nitems = lines[0].split(';').length
    if (lines.length>1) {
	nitems = Math.max(nitems, lines[1].split(';').length)
    }
    var allitems = Array(nitems)
    for (var i = 0; i < allitems.length; ++i) {
	allitems[i] = []
    }
    lines.forEach(function(l) {
	if (l.length == 0) return
	var items = l.split(';')
	for (var i = 0; i < items.length; ++i) {
	    allitems[i].push(Number(items[i]))
	}
    })
//    console.log('Read ' + lines.length + ' lines, total items: ' + allitems.length*lines.length)
    return allitems
}

xc.csv2xmlfilt = function(text, done) {
    console.log('xc.csv2xml')
    extractXPath(text, '/*/x:cont/text()', false, '', function(xcontdoc) {
        if (xcontdoc.nodeType == xcontdoc.DOCUMENT_FRAGMENT_NODE) {
	    var indoc = xcontdoc.textContent
	    var xml = xc.csv2xml(indoc)
	    done(xml)
	}
    })

}

xc.findParentByClass = function(x, cls) {
    if (x.classList.contains(cls)) {
	return x
    } else if (x.parentElement != undefined) {
	return xc.findParentByClass(x.parentElement, cls)
    }
    return undefined
}

xc.showSection = function(which, x) {
    var cont = xc.findParentByClass(x, 'xc-sections')
    var sects = cont.parentElement.querySelectorAll('.xc-section')
    sects.forEach(function(sec) {
	sec.style.display = 'none'
    })
    var sec = cont.parentElement.querySelector('#' + which)
    sec.style.display = 'block'
}

xc.getXML = xc.getMarkup = function(doc) {
    if (typeof doc == 'string') return doc
    else return doc.documentElement.outerHTML
}

xc.inject = function(id, html) {
    var el = document.querySelector('#' + id)
    if (el != null) {
	el.innerHTML = html
    }
}

xc.submitForm = function(form, url, done) {
    xc.ensureInput(form, 'csrfmiddlewaretoken')
    form.csrfmiddlewaretoken.value = xc.getCSRFToken()
    xlp.submitForm(form, url, done)
}

xc.ensureInput = function(form, name) {
    if (typeof name == "string") {
        if (!form.elements[name]) {
            form.innerHTML += '<input name="' + name + '" type="hidden"/>'
        }
    } else {
        for (var i in name) {
            xc.ensureInput(form, name[i])
        }
    }
}

xc.transformAndSaveAs = function(doc, filters, ofname, form, toDoc, done, render, append) {
    var updateconfxlp = xlp.mkXLP(filters, '/main/getf/')
    updateconfxlp.transform(doc, toDoc, function(resconf) {
        xc.ensureInput(form, 'path')
        xc.ensureInput(form, 'data')
        xc.ensureInput(form, 'csrfmiddlewaretoken')
	form.path.value = ofname
	form.data.value = toDoc ? resconf.documentElement.outerHTML : resconf.textContent
	form.csrfmiddlewaretoken.value = xc.getCSRFToken()
        var formAction = '/main/ajax_edit'
        if (append) {
            formAction = '/main/ajax_append'
        }
	xlp.submitForm(form, formAction, function(rdoc, req) {
	    console.log('Doc ' + doc.URL + ' transformed with ' + filters + ' and saved as ' + ofname)
            if (render) {
                processXData(undefined, req, function(res) {
                    done(res, req)
                })
            } else {
	        done(rdoc, req)
            }
	})
    })
}

// https://stackoverflow.com/questions/3730510/javascript-sort-array-and-return-an-array-of-indicies-that-indicates-the-positi
xc.sortWithIndices = function(toSort, datatype) {
  for (var i = 0; i < toSort.length; i++) {
    toSort[i] = [toSort[i], i];
  }
  var cmpNum = function(left, right) { return left[0] < right[0] ? -1 : 1; }
  var cmpText = function(left, right) { return left[0].localeCompare(right[0]) }
  var cmp = datatype == 'text' ? cmpText : cmpNum
  toSort.sort(cmp)
  toSort.sortIndices = [];
  for (var j = 0; j < toSort.length; j++) {
    toSort.sortIndices.push(toSort[j][1]);
    toSort[j] = toSort[j][0];
  }
  return toSort;
}

xc.ppActiveLink = function(ev) {
    var links = document.querySelectorAll('a')
    links.forEach((a) => {
	if (a.href == document.location.href) {
	    a.classList.add('xc-active-link')
	} else {
	    a.classList.remove('xc-active-link')
	}
    })
}

var ppSorts = function(ev) {
    var tms = document.querySelectorAll('.xc-sl-sort')
    tms.forEach(function(el) {
	if (el.dataset.sorted == '1') {
	    return
	}
	el.dataset.sorted = '1'
	var use = el.dataset.select
	var order = el.dataset.order || 'ascending'
	var datatype = el.dataset.datatype || 'text'

	var elems = Array.from(el.children)

	var vals = elems.map((k) => {
	    var sel = k.querySelector(use)
	    return sel.innerText
	})

	var sres = xc.sortWithIndices(vals, datatype)
	if (order != 'ascending') {
	    sres.sortIndices.reverse()
	}
	var res = []
	for (var i = 0; i < elems.length; ++i) {
	    res.push(elems[sres.sortIndices[i]])
	}

	el.innerHTML = res.map((k)=>k.outerHTML).join('')
    })
}

xc.number = function(val) {
    if (val == '') val = 'NaN'
    return Number(val)
}


xc.nsResolver = function(prefix) {
    var uri = prefix === "xhtml" ? 'http://www.w3.org/1999/xhtml' :
	prefix === "x" ? 'http://www.w3.org/1999/xhtml' :
	prefix === "xc" ? 'http://ai-and-it.de/xmlns/2020/xc' :
	null
    return uri
}


xc.xq = function(exp, node) {
    // https://stackoverflow.com/questions/19146056/document-evaluate-allways-returns-null-in-singlenodevalue-on-some-pages-sites
    var xqres = node.evaluate(exp, node, xc.nsResolver, XPathResult.ANY_TYPE, null);
    var res
    if (xqres.resultType == XPathResult.UNORDERED_NODE_ITERATOR_TYPE) {
	xqres = node.evaluate(exp, node, xc.nsResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
	res = []
	for (var i = 0; i < xqres.snapshotLength; ++i) {
	    var node = xqres.snapshotItem(i)
	    res.push(node)
	}
    } else if (xqres.resultType == XPathResult.NUMBER_TYPE) {
	res = xqres.numberValue
    } else if (xqres.resultType == XPathResult.STRING_TYPE) {
	res = xqres.stringValue
    } else if (xqres.resultType == XPathResult.BOOLEAN_TYPE) {
	res = xqres.booleanValue
    }
    return res
}

xc.sortCol = function(ev) {
    var t = event.target
    var ind = xc.xq('count(preceding-sibling::x:td)', t)
    var table = xc.xq('ancestor::x:table', t)[0]
    var rows = xc.xq('x:tbody/x:tr', table)
    var vals = rows.map(function(row) {
	var td = xc.xq('x:td', row)[ind]
	var fe = td.firstElementChild
	var val
	if (fe.dataset.flval != undefined) {
	    val = fe.dataset.flval
	} else {
	    val = td.innerText
	}
	return val
    })

    var order = t.dataset.order || 'ascending'
    var datatype = t.dataset.datatype || 'number'

    if (datatype == 'number') {
	var nvals = vals.map((k) => Number(k))
	if (nvals.length == nvals.filter((k) => String(k) != 'NaN').length) {
	    vals = nvals
	} else {
	    datatype = 'text'
	}
    }

    var sres = xc.sortWithIndices(vals, datatype)
    if (order != 'ascending') {
	sres.sortIndices.reverse()
    }
    var res = []
    for (var i = 0; i < rows.length; ++i) {
	res.push(rows[sres.sortIndices[i]])
    }

    table.querySelector('tbody').innerHTML = res.map((k)=>k.outerHTML).join('')

    xc.xq('../x:td', t).forEach((k) => {
	k.classList.remove('sort-descending')
	k.classList.remove('sort-ascending')
    })

    if (order == 'ascending') {
	t.dataset.order = 'descending'
	t.classList.add('sort-ascending')
	t.classList.remove('sort-descending')
    } else {
	t.dataset.order = 'ascending'
	t.classList.add('sort-descending')
	t.classList.remove('sort-ascending')
    }

    return false
}

xc.getID = function(path, done) {
    var rdata = 'path=' + path + '&incr=1&next_=counter&csrfmiddlewaretoken=' + xc.getCSRFToken()
    var headers = {'Content-type': 'application/x-www-form-urlencoded'}
    xlp.sendPost('/main/plain_counter', rdata, headers, function(stat, res) {
        var num = xc.xq('number(/*/xcontent/xc:*)', res.responseXML)
        done(num)
    })
}

xc.mkdir_p = function(path, done) {
    var comps = path.split('/')
    var path = ''
    comps.forEach((p)=> {
        var rdata = 'path=' + path + '&newdir=' + p + '&csrfmiddlewaretoken=' + xc.getCSRFToken()
        path += p + '/'
        var headers = {'Content-type': 'application/x-www-form-urlencoded'}
        xlp.sendPost('/main/ajax_newdir', rdata, headers, function(stat, res) {
            var num = xc.xq('number(/*/xcontent/xc:*)', res.responseXML)
            done(num1)
        })
    })
}

xc.registeredHandles = {}
xc.register = function(mode, handle) {
    if (!xc.registeredHandles[mode]) {
        xc.registeredHandles[mode] = []
    }
    xc.registeredHandles[mode].push(handle)
}

xc.mkMessage = function(mode, msg) {
    var res = ''
    res += '<div class="' + mode + '">' + msg + '</div>'
    return res
}

xc.showMessage = function(msg, timeout) {
    var p = document.querySelector('.doc-float-messages')
    if (!p) {
        p = document.querySelector('body')
    }
    p.innerHTML += msg
    if (!timeout) {
        timeout = 1800
    }
    if (timeout) {
        setTimeout(function() {
            try {
                var p = document.querySelector('.doc-float-messages')
                p.firstElementChild.remove()
            } catch {
            }
        }, timeout)
    }
}

xlp.addErrorHandler(function(msg, req) {
    console.error('an XLP request failed')
    xc.showMessage(xc.mkMessage('error', msg))
})
