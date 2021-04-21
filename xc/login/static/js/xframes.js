var xframes = {}

xframes.normalizePath = function(path) {
    if (path[0] == '/') {
        path = xlp.getbase() + path
    }
    var t = new URL(path)
    var p = t.pathname
    var pieces = p.split('/')
    pieces = pieces.filter((k)=> k.length>0)
    var np = pieces.join('/')
    if (p[p.length-1] == '/') {
        np += '/'
    }
    return t.origin + '/' + np + t.search
}

xframes.ajaxPathName = function(path) {
    var aurl = new URL(xframes.normalizePath(path))

    var pieces = aurl.pathname.split('/')
    var lastpieceI = pieces.length-1
    var lastpiece = pieces[lastpieceI]

    if (lastpiece == '') {
        if (pieces.length < 4) {
	    pieces = ['', 'main', '']
	    lastpiece = 'home'
        } else {
            lastpieceI -= 1
            lastpiece = pieces[lastpieceI]
        }
    }
    if (!lastpiece.startsWith('ajax_')) {
	pieces[lastpieceI] = 'ajax_' + lastpiece
    }

    var res = new URL(aurl.origin + pieces.join('/') + aurl.search) + ''
    return res
}

xframes.unajaxPathName = function(path) {
    var aurl = new URL(path)

    var pieces = aurl.pathname.split(/[\/]+/)
    var lastpiece = pieces[pieces.length-1]

    if (lastpiece.startsWith('ajax_')) {
        pieces[pieces.length-1] = lastpiece.substr(5)
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
//    console.log('history.pushState', retrURL)
}

xframes.mkXframes = function(frames, xsltbase) {
    var xlps = []
    for (var framen in frames) {
        var frame = frames[framen]
        if (frame.xlp == undefined) {
            xlps[framen] = xlp.mkXLP(frame.filters, xsltbase)
        } else {
            xlps[framen] = frame.xlp
        }
    }
    var render = function(indoc, done, preprocess) {
        var stepsDone = Array(frames.length);
        var stepsRes = Array(frames.length);
        [...Array(frames.length).keys()].forEach(function(framen) {
            stepsDone[framen] = 0
        });
        [...Array(frames.length).keys()].forEach(function(framen) {
            var frame = frames[framen]
            var x = xlps[framen]
            x.transform(indoc, function(result) {

		var lastStep = function(res) {
                    console.log('XLP chain ' + framen + ' done')
                    stepsDone[framen] = 1
                    stepsRes[framen] = result
                    if (stepsDone.every(function(x) { return x > 0 })) {
			console.log('Xframes Renderings done')
			done(stepsRes, stepsDone)
                    }
		}

                var resn = document.getElementById(frame.target)
                if (resn === null) {
                    console.error('XFrame target ' +  frame.target + ' not found')
		    lastStep()
                } else {
                    if (result.nodeType == result.ELEMENT_NODE) {
                        resn.innerHTML = result.outerHTML
			lastStep(resn)
                    } else if (result.nodeType == result.DOCUMENT_NODE
                               || result.nodeType == result.DOCUMENT_FRAGMENT_NODE) {
                        if (result.documentElement != null) {
			    var resHTML = result.documentElement.outerHTML
			    var invNode = document.getElementById('invisible')
			    console.log('Invisible children ' + invNode.childElementCount)
			    var newNode = document.createElement('div')
			    var nid = '' + (new Date()).getTime()
			    newNode.setAttribute('id', nid)
			    console.log('New Inv node ' + newNode.attributes.id.value + ' ' + nid)
			    invNode.appendChild(newNode)
			    newNode.innerHTML = resHTML
			    preprocess(newNode, function(res) {
				resHTML = newNode.innerHTML
				resn.innerHTML = resHTML
				var oldNode = invNode.removeChild(newNode)
				console.log('Inv node removed ' + oldNode.attributes.id.value + ' ' + nid)
				console.log('Invisible children ' + invNode.childElementCount)
				lastStep(resn)
			    })
                        } else {
                            resn.innerHTML = result.textContent
			    lastStep(resn)
                        }
                    } else {
                        resn.innerHTML = 'Transformation error: ' + result.nodeType + ': ' + result.URL 
			lastStep(resn)
                    }
                }
            })
        })
        console.log('Xframes renderings launched')
    }
    var renderRespHandler = function(status, request, done, src,url) {
        var indoc = request.responseXML
        if ((typeof indoc == "undefined") || (indoc === null)) {
            console.error('Xframes: no XML response from ' + src + '(' + url + ')')
        } else {
            render(indoc, function(res) {
                done(request, res)
            }, function(res, done) {
		console.log('No preprocess')
		done(res)
            })
        }
    }
    var renderData = function(src, doc, done) {
        renderRespHandler(0, doc, done, src, src)
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
    return xframes.staticurl + path
}

xframes.init = function() {
    console.log('xframes.init')
}

function xframes_init() {
    xframes.init()
}

console.log('xframes loaded')
