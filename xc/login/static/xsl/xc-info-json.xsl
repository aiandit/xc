<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/"> { "class": "<xsl:apply-templates mode="get-class"/>" } </xsl:template>

  <xsl:template match="text()" mode="get-class"/>

  <xsl:template match="x:*" mode="get-class">
    <xsl:value-of select="name()"/>
  </xsl:template>

  <xsl:template match="svg:svg" mode="get-class">svg</xsl:template>

  <xsl:template match="xhtml:*" mode="get-class">html</xsl:template>

  <xsl:template match="xc" mode="get-class">xc</xsl:template>

</xsl:stylesheet>
