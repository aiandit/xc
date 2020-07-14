<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:param name="defaults-doc-uri" select="'/main/getf/full/offer.xml'"/>
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

  <xsl:template match="x:cgi"/>

  <xsl:template match="x:texts">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:main"/>
        <xsl:with-param name="val" select="$defaults-doc//x:main"/>
        <xsl:with-param name="def">
          <main>Unser Angebot</main>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:sub"/>
        <xsl:with-param name="val" select="$defaults-doc//x:sub"/>
        <xsl:with-param name="def">
          <sub>Angebot Nr. 000</sub>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:body"/>
        <xsl:with-param name="val" select="$defaults-doc//x:body"/>
        <xsl:with-param name="def">
          <body>Gerne unterbreiten wir Ihnen folgendes Angebot</body>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:post"/>
        <xsl:with-param name="val" select="$defaults-doc//x:post"/>
        <xsl:with-param name="def">
          <post>Wir erwarten Ihre Rückmeldung</post>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="complete">
        <xsl:with-param name="exs" select="x:closing"/>
        <xsl:with-param name="val" select="$defaults-doc//x:closing"/>
        <xsl:with-param name="def">
          <post>Wir erwarten Ihre Rückmeldung</post>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
