// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Dynamics365.UIAutomation.Api.UCI;
using Microsoft.Dynamics365.UIAutomation.Browser;
using System;
using System.Security;

namespace Microsoft.Dynamics365.UIAutomation.Sample.AzureDevOps.ContactManagement
{
    [TestClass]
    public class CreateNewEntityUCIDevOps
    {
        private static string _username = "";
        private static string _password = "";
        private static BrowserType _browserType;
        private static Uri _xrmUri;

        public TestContext TestContext { get; set; }

        private static TestContext _testContext;

        [ClassInitialize]
        public static void Initialize(TestContext TestContext)
        {
            _testContext = TestContext;

            _username = _testContext.Properties["OnlineUsername"].ToString();
            _password = _testContext.Properties["OnlinePassword"].ToString();
            _xrmUri = new Uri(_testContext.Properties["OnlineCrmUrl"].ToString());
            _browserType = (BrowserType)Enum.Parse(typeof(BrowserType), _testContext.Properties["BrowserType"].ToString());
        }

        [TestCategory("ContactManagement")]
        [TestMethod]
        public void UCIDevOpsCreateNewEntity()
        {
            var client = new WebClient(TestSettings.Options);
            using (var xrmApp = new XrmApp(client))
            {
                xrmApp.OnlineLogin.Login(_xrmUri, _username.ToSecureString(), _password.ToSecureString());
                xrmApp.ThinkTime(500);
                xrmApp.Navigation.OpenApp("Contact Management");
                xrmApp.ThinkTime(500);
                xrmApp.Navigation.OpenSubArea("Main", "New Entities");
                xrmApp.ThinkTime(500);
                xrmApp.CommandBar.ClickCommand("New");
                xrmApp.ThinkTime(500);
                xrmApp.Entity.SetValue("ita_name", TestSettings.GetRandomString(5,15));
                xrmApp.ThinkTime(500);
                xrmApp.Entity.SetValue("ita_demosep23", TestSettings.GetRandomString(5, 15));
                xrmApp.ThinkTime(500);
                xrmApp.Entity.Save();
                
            }
            
        }
    }
}