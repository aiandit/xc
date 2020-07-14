<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fc="http://ai-and-it.de/xmlns/2020/fontcache"
  xmlns="http://ai-and-it.de/xmlns/2020/fontcache"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:key name="byfile" use="fc:file" match="fc:entry"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()|*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fc:entry">
    <xsl:if test="preceding-sibling::fc:entry[1]/fc:file != fc:file">
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates select="fc:file"/>
        <xsl:apply-templates select="key('byfile', fc:file)" mode="merge"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="fc:entry" mode="merge">
    <xsl:element name="{fc:key}">
      <xsl:value-of select="fc:value"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
