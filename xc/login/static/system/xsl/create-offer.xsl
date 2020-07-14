<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:include href="xc-utils.xsl"/>

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:variable name="template-doc-uri" select="'/main/getf/types/offer.xml'"/>
  <xsl:variable name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="counter-doc" select="document('/main/plain_id?path=t2/c1.xml')"/>

  <xsl:template match="/">
    <x>
      <cont>
        <xsl:apply-templates select="$template-doc" mode="to-xc"/>
      </cont>
    </x>
  </xsl:template>

  <xsl:template match="x:sub" mode="to-xcerp">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xcerp"/>
      <xsl:text> </xsl:text>
      <xsl:copy-of select="$counter-doc//x:counter"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
