var xframes = xframes || {}

xframes.log = function(txt) { if (xframes.debug) { console.log('XFr: ' + txt) } }
xframes.error = function(txt) { console.error('XFr: ' + txt) }

xframes.sections = ['main', 'login', 'register']
xframes.homepage = 'home'

xframes.ajaxPathName = function(path) {
    var aurl = new URL(path)

    var pieces = aurl.pathname.split(/[\/]+/)
    var sect = pieces.filter((k) => xframes.sections.indexOf(k) > -1)
    var sectind = pieces.indexOf(sect[0])
    if (sectind >= 0) {

	var page = pieces[sectind+1]
	if (!page.startsWith('ajax_')) {
	    pieces[sectind+1] = 'ajax_' + page
	}

    } else {

	pieces = ['', xframes.sections[0], 'ajax_' + xframes.homepage]

    }

    var res = new URL(aurl.origin + pieces.join('/') + aurl.search) + ''
    return res
}

xframes.unajaxPathName = function(path) {
    var aurl = new URL(path)

    var pieces = aurl.pathname.split(/[\/]+/)
    var sect = pieces.filter((k) => xframes.sections.indexOf(k) > -1)
    var sectind = pieces.indexOf(sect[0])
    var page = pieces[sectind+1]

    if (page.startsWith('ajax_')) {
        pieces[sectind+1] = page.substr(5)
    }

    var res = new URL(aurl.origin + pieces.join('/') + aurl.search) + ''
    return res
}

xframes.pushhist = function(request) {
    var retrURL = request.responseURL
    retrURL = xframes.unajaxPathName(retrURL)
    var retrTitle = 'XCerp - ' + retrURL
//    history.pushState({title: retrTitle, URL: retrURL}, retrTitle, retrURL)
    history.pushState(retrURL, '', retrURL)
//    xframes.log('history.pushState', retrURL)
}

xframes.mkXframes = function(frames, xsltbase) {
    var xlps = []
    for (var framen in frames) {
        var frame = frames[framen]
        if (frame.xlp == undefined) {
            xlps[framen] = xlp.mkXLP(frame.filters, xsltbase, null, frame.params)
        } else {
            xlps[framen] = frame.xlp
        }
    }
    var getHTML = function(result) {
	var html = ''
        if (result.documentElement != null) {
	    html = result.documentElement.outerHTML
        } else if (result.firstElementChild) {
	    var el = result.firstElementChild
	    while (el) {
		html += el.outerHTML
		el = el.nextElementSibling
	    }
	} else {
	    html = result.textContent
	}
	return html
    }
    var render = function(indoc, done, preprocess, params) {
	if (preprocess == undefined) {
	    preprocess = function(a, done) {
		done(a)
	    }
	}
        var stepsDone = Array(frames.length);
        var stepsRes = Array(frames.length);
        [...Array(frames.length).keys()].forEach(function(framen) {
            stepsDone[framen] = 0
        });
        [...Array(frames.length).keys()].forEach(function(framen) {
            var frame = frames[framen]
            var x = xlps[framen]
	    var toDoc = true
	    if (frame.toDoc != undefined) {
		toDoc = frame.toDoc
	    } else {
		toDoc = x.options && x.options.output && x.options.output == 'text' ? false : true
	    }
	    var container = frame.container || 'div'

            xframes.log('Xframes XLP chain ' + (framen+1) + ' ' + frame.target + ' of ' + frames.length + ' launched')
            xframes.log(frames[framen])
	    x.transform(indoc, toDoc, function(result) {

//                xframes.log('Xframes XLP chain ' + (framen+1) + ' transformed')
		var lastStep = function(res) {
                    xframes.log('Xframes XLP chain ' + (framen+1) + ' ' + frame.target + ' of ' + frames.length + ' done')
                    stepsDone[framen] = 1
                    stepsRes[framen] = result
                    if (stepsDone.every(function(x) { return x > 0 })) {
			xframes.log('Xframes all ' + frames.length + ' XLP chains done')
			done(stepsRes[stepsRes.length-1], stepsDone)
                    }
		}

                var resn = document.getElementById(frame.target)
                if (resn === null) {
                    xframes.error('XFrame target ' +  frame.target + ' not found')
		    lastStep()
                } else {
                    if (typeof result == 'string') {
                        resn.innerHTML = result
			lastStep(resn)
                    } else if (result.nodeType && result.nodeType == result.ELEMENT_NODE) {
                        resn.innerHTML = result.outerHTML
			lastStep(resn)
                    } else if (result.nodeType && (result.nodeType == result.DOCUMENT_NODE
						   || result.nodeType == result.DOCUMENT_FRAGMENT_NODE)) {
			var resHTML = getHTML(result)
			var invNode = document.getElementById('invisible')
//			xframes.log('Invisible children ' + invNode.childElementCount)
			var newNode = document.createElement(container)
			var nid = '' + (new Date()).getTime()
			newNode.setAttribute('id', nid)
//			xframes.log('New Inv node ' + newNode.attributes.id.value + ' ' + nid)
			invNode.appendChild(newNode)
			newNode.innerHTML = resHTML
			xframes.log('Xframes XLP chain ' + (framen+1) + ' ' + frame.target + ' preprocess')
			preprocess(newNode, function(res) {
			    xframes.log('Xframes XLP chain ' + (framen+1) + ' ' + frame.target + ' preprocessed')
			    resHTML = res.innerHTML
			    resn.innerHTML = resHTML
			    var oldNode = invNode.removeChild(newNode)
//			    xframes.log('Inv node removed ' + oldNode.attributes.id.value + ' ' + nid)
//			    xframes.log('Invisible children ' + invNode.childElementCount)
			    lastStep(resn)
			})
                    } else {
                        resn.innerHTML = 'Transformation error: ' + result.nodeType + ': ' + result.URL 
			lastStep(resn)
                    }
                }
            }, params || this.params)
        })
        //xframes.log('Xframes renderings launched')
    }
    var renderRespHandler = function(indoc, request, done, src,url) {
        if ((typeof indoc == "undefined") || (indoc === null)) {
            xframes.error('Xframes: no XML response from ' + src + '(' + url + ')')
            done(request, -1)
        } else {
	    if (src && src.dataset && src.dataset.formSubmitBackground) {
		xframes.log('Form submitted in BG: ' + status)
		done(request, 0)
	    } else {
		render(indoc, function(res) {
                    done(request, res)
		}, function(res, done) {
		    xframes.log('No preprocess')
		    done(res)
		})
	    }
        }
    }
    var renderLink = function(src, url, done, cached) {
	var getfun = cached ? xlp.loadCached : xlp.loadXML
        getfun(url, (a,b)=>renderRespHandler(a,b,done, src,url))
    }
    var renderFormSubmit = function(src, url, done) {
        var method = 'GET'
        if (typeof src.method != "undefined") {
            method = src.method
        }
        xlp.reqXML(src, {URL: url, method: method, callback: (a,b)=>renderRespHandler(a,b,done, src,url)})
    }
    var Xframes = {
	renderRespHandler: renderRespHandler,
        frames: frames,
        xsltbase: xsltbase,
        xlps: xlps,
        render: render,
        renderLink: renderLink,
        renderFormSubmit: renderFormSubmit
    }
    return Xframes
}

xframes.spath = function(path) {
    return xframes.xframe.staticurl + path
}
