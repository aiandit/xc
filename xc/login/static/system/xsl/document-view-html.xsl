<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="template-doc-uri" select="'/main/getf/templates/html/offer.html'"/>
  <xsl:param name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="x:poll">
    <div id="poll-{generate-id()}" class="poll" data-poll-url="{.}" data-poll-interval="{@interval}">
      <h5>Poll</h5>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

</xsl:stylesheet>
