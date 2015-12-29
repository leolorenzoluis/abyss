/*! grafana - v2.5.0 - 2015-10-28
 * Copyright (c) 2015 Torkel Ödegaard; Licensed Apache-2.0 */

define(["require","exports","app/plugins/datasource/influxdb/query_builder","test/lib/common"],function(a,b,c,d){d.describe("InfluxQueryBuilder",function(){d.describe("series with mesurement only",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",groupBy:[{type:"time",interval:"auto"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE $timeFilter GROUP BY time($interval)')})}),d.describe("series with math expr and as expr",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",fields:[{name:"test",func:"max",mathExpr:"*2",asExpr:"new_name"}],groupBy:[{type:"time",interval:"auto"}]}),b=a.build();d.expect(b).to.be('SELECT max("test")*2 AS "new_name" FROM "cpu" WHERE $timeFilter GROUP BY time($interval)')})}),d.describe("series with single tag only",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",groupBy:[{type:"time",interval:"auto"}],tags:[{key:"hostname",value:"server1"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE "hostname" = \'server1\' AND $timeFilter GROUP BY time($interval)')}),d.it("should switch regex operator with tag value is regex",function(){var a=new c({measurement:"cpu",groupBy:[{type:"time",interval:"auto"}],tags:[{key:"app",value:"/e.*/"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE "app" =~ /e.*/ AND $timeFilter GROUP BY time($interval)')})}),d.describe("series with multiple fields",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",tags:[],groupBy:[{type:"time",interval:"auto"}],fields:[{name:"tx_in",func:"sum"},{name:"tx_out",func:"mean"}]}),b=a.build();d.expect(b).to.be('SELECT sum("tx_in") AS "tx_in", mean("tx_out") AS "tx_out" FROM "cpu" WHERE $timeFilter GROUP BY time($interval)')})}),d.describe("series with multiple tags only",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",groupBy:[{type:"time",interval:"auto"}],tags:[{key:"hostname",value:"server1"},{key:"app",value:"email",condition:"AND"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE "hostname" = \'server1\' AND "app" = \'email\' AND $timeFilter GROUP BY time($interval)')})}),d.describe("series with tags OR condition",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",groupBy:[{type:"time",interval:"auto"}],tags:[{key:"hostname",value:"server1"},{key:"hostname",value:"server2",condition:"OR"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE "hostname" = \'server1\' OR "hostname" = \'server2\' AND $timeFilter GROUP BY time($interval)')})}),d.describe("series with groupByTag",function(){d.it("should generate correct query",function(){var a=new c({measurement:"cpu",tags:[],groupBy:[{type:"time",interval:"auto"},{type:"tag",key:"host"}]}),b=a.build();d.expect(b).to.be('SELECT mean("value") AS "value" FROM "cpu" WHERE $timeFilter GROUP BY time($interval), "host"')})}),d.describe("when building explore queries",function(){d.it("should only have measurement condition in tag keys query given query with measurement",function(){var a=new c({measurement:"cpu",tags:[]}),b=a.buildExploreQuery("TAG_KEYS");d.expect(b).to.be('SHOW TAG KEYS FROM "cpu"')}),d.it("should handle regex measurement in tag keys query",function(){var a=new c({measurement:"/.*/",tags:[]}),b=a.buildExploreQuery("TAG_KEYS");d.expect(b).to.be("SHOW TAG KEYS FROM /.*/")}),d.it("should have no conditions in tags keys query given query with no measurement or tag",function(){var a=new c({measurement:"",tags:[]}),b=a.buildExploreQuery("TAG_KEYS");d.expect(b).to.be("SHOW TAG KEYS")}),d.it("should have where condition in tag keys query with tags",function(){var a=new c({measurement:"",tags:[{key:"host",value:"se1"}]}),b=a.buildExploreQuery("TAG_KEYS");d.expect(b).to.be("SHOW TAG KEYS WHERE \"host\" = 'se1'")}),d.it("should have no conditions in measurement query for query with no tags",function(){var a=new c({measurement:"",tags:[]}),b=a.buildExploreQuery("MEASUREMENTS");d.expect(b).to.be("SHOW MEASUREMENTS")}),d.it("should have where condition in measurement query for query with tags",function(){var a=new c({measurement:"",tags:[{key:"app",value:"email"}]}),b=a.buildExploreQuery("MEASUREMENTS");d.expect(b).to.be("SHOW MEASUREMENTS WHERE \"app\" = 'email'")}),d.it("should have where tag name IN filter in tag values query for query with one tag",function(){var a=new c({measurement:"",tags:[{key:"app",value:"asdsadsad"}]}),b=a.buildExploreQuery("TAG_VALUES","app");d.expect(b).to.be('SHOW TAG VALUES WITH KEY = "app"')}),d.it("should have measurement tag condition and tag name IN filter in tag values query",function(){var a=new c({measurement:"cpu",tags:[{key:"app",value:"email"},{key:"host",value:"server1"}]}),b=a.buildExploreQuery("TAG_VALUES","app");d.expect(b).to.be('SHOW TAG VALUES FROM "cpu" WITH KEY = "app" WHERE "host" = \'server1\'')}),d.it("should switch to regex operator in tag condition",function(){var a=new c({measurement:"cpu",tags:[{key:"host",value:"/server.*/"}]}),b=a.buildExploreQuery("TAG_VALUES","app");d.expect(b).to.be('SHOW TAG VALUES FROM "cpu" WITH KEY = "app" WHERE "host" =~ /server.*/')}),d.it("should build show field query",function(){var a=new c({measurement:"cpu",tags:[{key:"app",value:"email"}]}),b=a.buildExploreQuery("FIELDS");d.expect(b).to.be('SHOW FIELD KEYS FROM "cpu"')})})})});