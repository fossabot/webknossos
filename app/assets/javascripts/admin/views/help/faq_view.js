import React from "react";

const FAQView = () => (
  <div className="container help">
    <h3>FAQ</h3>
    <p />
    <h4>Which browsers are supported for webKnossos?</h4>
    <p>
      webKnossos runs best with the latest version of Google Chrome. We use it to test and develop
      the software and recommend it.
    </p>
    <p>
      However, any other modern browser in their latest version should work as well. We have had
      good success with the following browsers:
    </p>
    <ul>
      <li>Firefox 51+</li>
      <li>Opera 43+</li>
      <li>Edge 14+</li>
      <li>Safari 10</li>
    </ul>
    <p>Internet Explorer is not supported.</p>
    <h4>
      <a name="taskqueries" />What are possible task queries?
    </h4>
    <p>
      You can use every possible mongo db query in the task query field. That includes quering for
      specific attribute values or for ranges. Here are some examples:
    </p>
    <p>Query for a specific ID</p>
    <pre className="code" ace-mode="ace/mode/javascript" ace-theme="ace/theme/clouds">
      {`{
  "_id": {"$oid" : "56cb594a16000045b4d0f273"}
}`}
    </pre>
    <p>Query for multiple IDs</p>
    <pre className="code" ace-mode="ace/mode/javascript" ace-theme="ace/theme/clouds">
      {`{
  "_id": {"$in": [
      {"$oid" : "56cb594a16000045b4d0f273"},
      {"$oid" : "56cb579916000001b4d0e10b"},
    ]}
}`}
    </pre>
    <p>Query for two projects at the same time</p>
    <pre className="code" ace-mode="ace/mode/javascript" ace-theme="ace/theme/clouds">
      {`{
  "_project": { "$in" : ["MEC_st218_wholeCells3", "MEC_st218_wholeCells"] }
}`}
    </pre>
    <p>Query for a certain time range</p>
    <pre className="code" ace-mode="ace/mode/javascript" ace-theme="ace/theme/clouds">
      {`{
  "created": { "$gte" : 1467093444000, "$lte" : 1468095383000 }
}`}
    </pre>
    <p>Query for all active tasks of a project</p>
    <pre className="code" ace-mode="ace/mode/javascript" ace-theme="ace/theme/clouds">
      {`{
  "_project": "ek0563_Training",
  "isActive" : true
}`}
    </pre>
  </div>
);

export default FAQView;
