<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div class="measurement-result-files">
      <h4>Measurement Result Files</h4>
      <div class="measurement-result-file-list">
	<xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="finfo">
    <table class="collection">
      <tr>
        <td colspan="4"><xsl:value-of select="count(item)"/> Items</td>
      </tr>
      <xsl:apply-templates select="item">
        <xsl:sort select="name" order="descending" data-type="text"/>
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <xsl:template match="finfo/item">
    <tr>
      <td><a href="javascript:meas.loadMeasurement('{path}')"><xsl:value-of select="name[. != '']|path"/></a></td>
      <td><a class="xc-nocatch" href="/main/get/{path}">Download</a></td>
      <td class="unit-value">
       <span class="unit" data-unit="B" data-targetunit="MB"><xsl:value-of select="statdict/st_size"/>&#xa0;B</span></td>
      <td><span class="unixtm"><xsl:value-of select="statdict/st_mtime"/></span></td>
    </tr>
  </xsl:template>

  <xsl:template match="lsl">
    <div class="file-info">
      <xsl:apply-templates select="finfo"/>
    </div>
  </xsl:template>

</xsl:stylesheet>
