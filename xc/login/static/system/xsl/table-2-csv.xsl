<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xhtml:table">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xhtml:tr">
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:td">
    <xsl:value-of select="."/>
    <xsl:text>,</xsl:text>
  </xsl:template>

</xsl:stylesheet>
