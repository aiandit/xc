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
      <div class="poll" data-poll-url="/main/ajax_ps?pid={.}" data-poll-interval="1000" id="procinfo">
	abrufen!!!
      </div>
      <a href="/main/path?path=measurements">View Results</a>
    </div>
  </xsl:template>
  
</xsl:stylesheet>
