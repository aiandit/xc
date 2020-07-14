<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fc="http://ai-and-it.de/xmlns/2020/fontcache"
  xmlns="http://ai-and-it.de/xmlns/2020/fontcache"
  version="1.0">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match="/">
    <xsl:text>File;Family;Subfamily;Key&#xa;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:template match="fc:entry">
    <xsl:value-of select="fc:file"/>;"<xsl:value-of select="fc:Family"/>";"<xsl:value-of select="fc:Subfamily"/>";"<xsl:value-of select="@key"/>"<xsl:text>&#xa;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
