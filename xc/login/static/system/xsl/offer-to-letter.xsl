<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="x:cgi"/>

  <xsl:template match="x:offer">
    <letter>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="x:address"/>
      <texts>
        <xsl:apply-templates select="x:texts/x:main"/>
        <xsl:apply-templates select="x:texts/x:sub"/>
      </texts>
      <body>
        <div>
          <xsl:apply-templates select="x:texts/x:body" mode="children"/>
        </div>
        <xsl:apply-templates select="x:table"/>
        <div>
          <xsl:apply-templates select="x:texts/x:post" mode="children"/>
        </div>
        <div>
          <xsl:apply-templates select="x:texts/x:closing" mode="children"/>
        </div>
      </body>
    </letter>
  </xsl:template>

</xsl:stylesheet>
