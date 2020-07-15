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
      <h4>Process Info</h4>
      <div>
	<xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:pid">
    <span>Process ID (PID): <xsl:value-of select="."/></span>
    <div>
      <h5>Mesaurement process Info</h5>
      <div>
	<span>Command: </span>
	<span class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=command"
	      data-postprocess="psSingleField"
	      data-poll-interval="5000">
	</span>
      </div>
      <div>
	<span>Start time:</span>
	<span class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=start"
	      data-postprocess="psSingleField"
	      data-poll-interval="5000">
	</span>
      </div>
      <table>
	<tr>
	  <th>CPU (%)</th><th>Memory (%)</th>
	</tr>
	<tr class="poll" data-poll-url="/main/plain_ps?pid={.}&amp;fields=pcpu&amp;fields=pmem"
	    data-postprocess="psMultiField"
	    data-poll-interval="1000">
	</tr>
      </table>
      <a href="/main/path?path=measurements">View Results</a>
      <form action="/main/action" method="post">
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
      </form>
    </div>
  </xsl:template>
  
</xsl:stylesheet>
