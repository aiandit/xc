<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:variable name="indent" select="'                                                                   '"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="normalize-space()"/>
  </xsl:template>

  <xsl:template match="*" mode="pindent">
    <xsl:value-of select="substring($indent, 0, count(ancestor::*)+1)"/>
    <xsl:apply-templates select="."/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="text()" mode="pindent">
    <xsl:if test="normalize-space(.)">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:for-each select="*|text()">
        <xsl:apply-templates select="." mode="pindent"/>
      </xsl:for-each>
      <xsl:value-of select="substring($indent, 0, count(ancestor::*)+1)"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[count(text()[normalize-space(.) != ''])>0]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[not(*)]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
