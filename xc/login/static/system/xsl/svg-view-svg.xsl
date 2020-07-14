<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="copy.xsl"/>

  <xsl:template match="/">
    <xsl:apply-templates select="(/x:*/x:cont/*|/*)[last()]"/>
  </xsl:template>

</xsl:stylesheet>
