<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:alt="http://example.com/XSL/"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:variable name="xsl-xmlns" select="'http://www.w3.org/1999/XSL/Transform'"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="alt:*">
    <xsl:element name="xsl:{local-name()}" namespace="{$xsl-xmlns}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
