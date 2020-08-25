<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <h4>Measurement Process Info</h4>
      <div>
	<xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:file">
    <div class="measurement-file">
      <div id="measurement-file">
	Result file: <a href="javascript:meas.loadMeasurement('{.}');"><xsl:value-of select="."/></a>
      </div>
      <div id="result-feedback">
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:log">
    <div class="measurement-log">
      Log file: <a href="/main/path?path={.}"><code><xsl:value-of select="."/></code></a>
      <br/>
      <code class="poll" data-poll-url="/main/getf/{.}"
	  data-postprocess="psSingleField"
	  data-poll-interval="1000">
      </code>
    </div>
  </xsl:template>

  <xsl:template match="x:pid">
    <div class="measurement-process">
      <table>
	<tr>
	  <th>PID</th><th>CPU (%)</th><th>Memory (%)</th><th>Duration</th><th>CPU Time</th><th>State</th>
	</tr>
	<tr class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=pid&amp;fields=pcpu&amp;fields=pmem&amp;fields=etime&amp;fields=time&amp;fields=s"
	    data-postprocess="psMultiField"
	    data-poll-interval="1000">
	</tr>
      </table>
      <h5 class="oc-head">More</h5>
      <div class="oc-body">
	<table>
	  <tr>
	    <td>Command: </td>
	    <td class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=command"
	      data-postprocess="psSingleField"
	      data-poll-interval="50000">
	    </td>
	  </tr>
	  <tr>
	    <td>Started:</td>
	    <td class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=lstart"
		data-postprocess="psSingleField"
		data-poll-interval="50000">
	    </td>
	  </tr>
	  <tr>
	    <td>TTY:</td>
	    <td class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=tty"
		data-postprocess="psSingleField"
		data-poll-interval="50000">
	    </td>
	  </tr>
	  <tr>
	    <td>Major faults:</td>
	    <td class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=maj_flt"
		data-postprocess="psSingleField"
		data-poll-interval="50000">
	    </td>
	  </tr>
	  <tr>
	    <td>Minor faults:</td>
	    <td class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=min_flt"
		data-postprocess="psSingleField"
		data-poll-interval="50000">
	    </td>
	  </tr>
	</table>
      </div>
      <a href="/main/path?path=measurements">View Results</a>

<!--      <form action="/main/action" method="post">
	<fieldset>
	  <legend>Stop Measurement</legend>
	  <input type="hidden" name="path" value="bin/stop-measurement.sh"/>
	  <input type="hidden" name="next_" value="ajax_path?path=/"/>
	  <input type="hidden" name="csrfmiddlewaretoken">
	    <xsl:attribute name="value">
	      <xsl:value-of select="/*/x:cgi/x:csrfmiddlewaretoken"/>
	    </xsl:attribute>
	  </input>
	  <input type="submit"/>
	</fieldset>
      </form> -->
    </div>
  </xsl:template>
  
</xsl:stylesheet>
