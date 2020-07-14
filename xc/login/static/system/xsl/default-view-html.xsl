<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
                version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="text()" mode="xml-dump">
    <span>
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="xml-dump">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:if test="namespace-uri() != namespace-uri(..)">
      <xsl:text> xmlns="</xsl:text>
      <xsl:value-of select="namespace-uri()"/>
      <xsl:text>"</xsl:text>
    </xsl:if>
    <xsl:for-each select="@*">
      <xsl:text> </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>="</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>"</xsl:text>
    </xsl:for-each>
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="xml-dump"/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>


  <xsl:template match="*" mode="view">
    <code style="white-space: pre;">
      <xsl:apply-templates select="." mode="xml-dump"/>
    </code>
  </xsl:template>

  <xsl:template match="/">
    <div>
      <h4>Default View</h4>
      <p>No view class found in this document.</p>
      <xsl:apply-templates select="(/x:*/x:cont/*|*)[last()]" mode="view"/>
    </div>
  </xsl:template>

</xsl:stylesheet>
