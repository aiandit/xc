<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x='http://johannes-willkomm.de/xml/code-xml/'
                xmlns:c='http://johannes-willkomm.de/xml/code-xml/attributes/'
                xmlns:i='http://johannes-willkomm.de/xml/code-xml/ignore/'
                xmlns:fc="http://ai-and-it.de/xmlns/2020/fontcache"
  xmlns="http://ai-and-it.de/xmlns/2020/fontcache"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:template match="/">
    <fontcache version="1.0">
      <xsl:apply-templates/>
    </fontcache>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:template match="x:NEWLINE">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:COLON">
    <entry>
      <file>
        <xsl:apply-templates select="x:*[1]" mode="get-text"/>
      </file>
      <key>
        <xsl:apply-templates select="x:*[2]" mode="get-text"/>
      </key>
      <value>
        <xsl:apply-templates select="x:*[3]" mode="get-text"/>
      </value>
    </entry>
  </xsl:template>

  <xsl:template match="text()" mode="get-text"/>

  <xsl:template match="c:t|i:*" mode="get-text">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
