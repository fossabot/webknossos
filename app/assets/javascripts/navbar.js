// @flow
/* eslint-disable react/prefer-stateless-function */

import React from "react";
import { Layout, Menu, Icon } from "antd";
import { Link } from "react-router-dom";
import { connect } from "react-redux";
import app from "app";
import Request from "libs/request";
import LoginView from "admin/views/auth/login_view";

import type { OxalisState } from "oxalis/store";
import type { APIUserType } from "admin/api_flow_types";

const { SubMenu } = Menu;
const { Header } = Layout;

type Props = {
  isAuthenticated: boolean,
  activeUser: APIUserType,
};

class Navbar extends React.PureComponent<Props> {
  render() {
    return (
      <Header style={{ padding: 0 }}>
        <Menu
          mode="horizontal"
          defaultSelectedkeys={[app.history.location.pathname]}
          style={{ lineHeight: "64px" }}
          theme="dark"
        >
          <Menu.Item key="0">
            <Link to="/" style={{ fontWeight: 400 }}>
              <span className="logo" />
              webKnossos
            </Link>
          </Menu.Item>
          {this.props.isAuthenticated ? (
            [
              <Menu.Item key="/dashboard">
                <Link to="/dashboard">
                  <Icon type="home" />
                  Dashboard
                </Link>
              </Menu.Item>,
              <SubMenu
                key="sub1"
                title={
                  <span>
                    <Icon type="setting" />Administration
                  </span>
                }
              >
                <Menu.Item key="/users">
                  {" "}
                  <Link to="/users">Users</Link>
                </Menu.Item>
                <Menu.Item key="/teams">
                  {" "}
                  <Link to="/teams">Teams</Link>
                </Menu.Item>
                <Menu.Item key="/projects">
                  {" "}
                  <Link to="/projects">Projects</Link>
                </Menu.Item>
                <Menu.Item key="/tasks">
                  {" "}
                  <Link to="/tasks">Tasks</Link>
                </Menu.Item>
                <Menu.Item key="/taskTypes">
                  {" "}
                  <Link to="/taskTypes">Task Types</Link>
                </Menu.Item>
                <Menu.Item key="/scripts">
                  {" "}
                  <Link to="/scripts">Scripts</Link>
                </Menu.Item>
              </SubMenu>,
              <SubMenu
                key="sub2"
                title={
                  <span>
                    <Icon type="line-chart" />Statistics
                  </span>
                }
              >
                <Menu.Item key="/tasks/overview">
                  <Link to="/tasks/overview">Overview</Link>
                </Menu.Item>
                <Menu.Item key="/statistics">
                  <Link to="/statistics">Weekly</Link>
                </Menu.Item>
              </SubMenu>,
              <SubMenu
                key="sub3"
                title={
                  <span>
                    <Icon type="medicine-box" />Help
                  </span>
                }
              >
                <Menu.Item key="/help/faq">
                  <a target="_blank" href="/help/faq">
                    FAQ
                  </a>
                </Menu.Item>
                <Menu.Item key="11">
                  <a target="_blank" href="/assets/docs/frontend-api/index.html">
                    Frontend API Documentation
                  </a>
                </Menu.Item>
                <Menu.Item key="/help/keyboardshortcuts">
                  <a target="_blank" href="/help/keyboardshortcuts">
                    keyboard Shortcuts
                  </a>
                </Menu.Item>
              </SubMenu>,
              <Menu.Item key="13">
                <a href="https://discuss.webknossos.org" target="_blank" rel="noopener noreferrer">
                  <Icon type="notification" />
                  Discussion Board
                </a>
              </Menu.Item>,
              <SubMenu
                key="sub4"
                className="pull-right"
                title={
                  <span>
                    <Icon type="user" />
                    {`${this.props.activeUser.firstName} ${this.props.activeUser.lastName}`}
                  </span>
                }
              >
                <Menu.Item key="resetpassword">
                  <Link to="/reset">Reset Password</Link>
                </Menu.Item>
                <Menu.Item key="logout">
                  <Link
                    to="/"
                    onClick={() => {
                      Request.receiveJSON("/api/logout").then(() => window.location.reload());
                    }}
                  >
                    Logout
                  </Link>
                </Menu.Item>
              </SubMenu>,
            ]
          ) : (
            <Menu.Item key="login">
              <LoginView layout="inline" />
            </Menu.Item>
          )}
        </Menu>
      </Header>
    );
  }
}

const mapStateToProps = (state: OxalisState) => ({
  activeUser: state.activeUser,
});

export default connect(mapStateToProps)(Navbar);
