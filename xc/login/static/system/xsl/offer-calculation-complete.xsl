<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:param name="defaults-doc-uri" select="'/main/getf/company/info.xml'"/>
  <xsl:param name="defaults-doc" select="document($defaults-doc-uri)"/>

  <xsl:include href="xc-utils.xsl"/>


  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="x:calculation">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:cur"/>
        <xsl:with-param name="val" select="$defaults-doc//x:cur"/>
        <xsl:with-param name="def">
          <country>€</country>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:uststz"/>
        <xsl:with-param name="val" select="$defaults-doc//x:uststz"/>
        <xsl:with-param name="def">
          <country>0.18</country>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
