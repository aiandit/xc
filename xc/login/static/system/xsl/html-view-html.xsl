<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:include href="copy.xsl"/>
  
  <xsl:template match="/">
    <div>
      <xsl:apply-templates mode="render"/>
    </div>
  </xsl:template>

  <xsl:template match="text()" mode="render"/>
  
  <xsl:template match="xhtml:*" mode="render">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
