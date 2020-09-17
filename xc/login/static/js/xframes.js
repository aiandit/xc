var xframes = xframes || {}

xframes.ajaxPathName = function(path) {
    var aurl = new URL(path)

    var pieces = aurl.pathname.split(/[\/]+/)
    var lastpiece = pieces[pieces.length-1]

    pieces[pieces.length-1] = 'ajax_' + lastpiece

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
    var render = function(indoc, done) {
        var stepsDone = Array(frames.length);
        var stepsRes = Array(frames.length);
        [...Array(frames.length).keys()].forEach(function(framen) {
            stepsDone[framen] = 0
        });
        [...Array(frames.length).keys()].forEach(function(framen) {
            var frame = frames[framen]
            var x = xlps[framen]
            x.transform(indoc, true, function(result) {
                // console.log('Get result: ' + frame.target)
                var resn = document.getElementById(frame.target)
                if (resn === null) {
                    console.error('Target not found')
                } else {
                    // console.log('Get result: ' + resn)
                    // console.log('Get result: ' + result)
                    if (result.nodeType == result.ELEMENT_NODE) {
                        resn.innerHTML = result.outerHTML
                    } else if (result.nodeType == result.DOCUMENT_NODE
                               || result.nodeType == result.DOCUMENT_FRAGMENT_NODE) {
                        // xmlns:transformiix="http://www.mozilla.org/TransforMiix"
                        if (result.documentElement != null) {
                            if (result.documentElement.nodeName == 'transformiix:result') {
                                resn.innerHTML = result.documentElement.innerHTML
                            } else {
                                resn.innerHTML = result.documentElement.outerHTML
                            }
                        } else {
                            resn.innerHTML = result.textContent
                        }
                    } else {
                        resn.innerHTML = 'Transformation error: ' + result.nodeType + ': ' + result.URL 
                    }
                }
                console.log('XLP chain ' + framen + ' done')
                stepsDone[framen] = 1
                stepsRes[framen] = result
//                console.log('Xframes Rendering ' + framen + ' done')
                // console.log(stepsDone)
                // console.log(stepsDone.every(function(x) { x > 0 }))
                if (stepsDone.every(function(x) { return x > 0 })) {
                    console.log('Xframes Renderings done')
                    done(stepsRes[stepsRes.length-1], stepsDone)
                }
            })
        })
        console.log('Xframes renderings launched')
    }
    var renderRespHandler = function(status, request, done) {
        var indoc = request.responseXML
        if ((typeof indoc == "undefined") || (indoc === null)) {
            console.error('Xframes: no XML response from ' + src + '(' + url + ')')
        } else {
            render(indoc, function(res) {
                done(request, res)
            })
        }
    }
    var renderLink = function(src, url, done) {
        xlp.reqXML(src, {URL: url, method: 'GET', callback: (a,b)=>renderRespHandler(a,b,done)})
    }
    var renderFormSubmit = function(src, url, done) {
        var method = 'GET'
        if (typeof src.method != "undefined") {
            method = src.method
        }
        xlp.reqXML(src, {URL: url, method: method, callback: (a,b)=>renderRespHandler(a,b,done)})
    }
    var Xframes = {
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
