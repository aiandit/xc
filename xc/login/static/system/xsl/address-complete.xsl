<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="defaults-doc-uri" select="'/main/getf/company/info.xml'"/>
  <xsl:param name="defaults-doc" select="document($defaults-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="xc-utils.xsl"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:address">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:country"/>
        <xsl:with-param name="val" select="$defaults-doc//x:country"/>
        <xsl:with-param name="def">
          <country>Deutschland</country>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:city"/>
        <xsl:with-param name="val" select="$defaults-doc//x:city"/>
        <xsl:with-param name="def">
          <city>Aachen</city>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:postcode"/>
        <xsl:with-param name="val" select="$defaults-doc//x:postcode"/>
        <xsl:with-param name="def">
          <postcode>52074</postcode>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
