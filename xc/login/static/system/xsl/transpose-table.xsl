<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xhtml:*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:table">
    <xsl:variable name="this" select="."/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each select="xhtml:tr[1]/xhtml:td">
	<tr>
	  <xsl:comment>Get items nr <xsl:value-of select="position()"/> from all rows</xsl:comment>
	  <xsl:apply-templates select="$this/xhtml:tr[position()>1]" mode="get-nth-item">
	    <xsl:with-param name="n" select="position()"/>
	  </xsl:apply-templates>
	</tr>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:tr" mode="get-nth-item">
    <xsl:param name="n" select="0"/>
    <xsl:apply-templates select="xhtml:td[$n]"/>
  </xsl:template>

</xsl:stylesheet>
