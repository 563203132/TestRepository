import styles from './style.postcss';

import React, { Component } from 'react';
import { connect, Button } from 'omni-common-ui';
import 'html2canvas';
import jsPDF from 'jspdf';
import CoveredInClass from 'containers/CoveredInClass/model';
import mockData from './mockdata';
import { SpringGrid, measureItems, layout } from 'react-stonecutter';
import CardBlock from 'components/CardBlock';
import Detailsboard from 'components/Detailsboard';

let doc = new jsPDF('p', 'mm');
let currentNumber = 1;
const SmartSpringGrid = measureItems(SpringGrid);

class CoveredInClassExport extends Component {
  constructor(props) {
    super(props);
    this._onrendered = this._onrendered.bind(this);
    this.state = {
      paginationSessions: [],
    };
  }

  _exportPage() {
    doc = new jsPDF('p', 'mm');
    const allSessionTables = document.getElementsByName('section');
    for (let i = 0; i < allSessionTables.length; i++) {
      window.html2canvas(allSessionTables[i], {
        onrendered: this._onrendered,
      });
    }
  }

  _onrendered(canvas) {
    const imgData = canvas.toDataURL('image/jpeg');
    if (currentNumber > 1) {
      doc.addPage();
    }
    doc.addImage(imgData, 'jpeg', 10, 10);
    const totalNumber = document.getElementsByName('section').length;
    if (currentNumber === totalNumber) {
      doc.save('rendered-file.pdf');
      currentNumber = 1;
    }

    currentNumber++;
  }

  _calcHeight(node, sessionId) {
    if (node && node.clientHeight > 710 && this.state.paginationSessions.indexOf(sessionId) < 0) {
      const sessions = this.state.paginationSessions;
      sessions.push(sessionId);
      this.setState({ paginationSessions: sessions });
    }
  }

  _renderSessions() {
    return mockData.map(jsondata => {
      const data = CoveredInClass.create(jsondata);

      if (this.state.paginationSessions.indexOf(jsondata.cicId) < 0) {
        return <div className={styles.CoveredInClassExport_frame}>
          <div name="section" className={styles.CoveredInClassExport_section}>
            {this._renderHeader()}
            <div ref={node => this._calcHeight(node, jsondata.cicId)}
                className={styles.CoveredInClassExport_content}>
              {this._renderCategories(data.cicCategories)}
              {this._renderPageActivitiesPart(data.cicActivities)}
            </div>
            {this._renderFooter()}
          </div>
        </div>;
      }

      return <div>
        <div className={styles.CoveredInClassExport_frame}>
          <div name="section" className={styles.CoveredInClassExport_section}>
            {this._renderHeader()}
            <div className={styles.CoveredInClassExport_content}>
              {this._renderCategories(data.cicCategories)}
            </div>
            {this._renderFooter()}
          </div>
        </div>
        <div className={styles.CoveredInClassExport_frame}>
          <div name="section" className={styles.CoveredInClassExport_section}>
            {this._renderHeader()}
            <div className={styles.CoveredInClassExport_content}>
              {this._renderPageActivitiesPart(data.cicActivities)}
            </div>
            {this._renderFooter()}
          </div>
        </div>
      </div>;
    });
  }

  _renderCategories(categories) {
    return <SmartSpringGrid component="ul"
        className={styles.CoveredInClassExport_content_grid}
        columns={2}
        columnWidth={357}
        gutterWidth={5}
        gutterHeight={5}
        layout={layout.pinterest}>
      {
        categories.map(categoryObject =>
          <li style={{ width: '357px' }}>
            <div className={styles.CoveredInClassExport_content_category}>
              <div className={styles.CoveredInClassExport_content_category_title}>
                {categoryObject.cicCategoryName}
              </div>
              {this._renderCategoriesItems(categoryObject.cicCategoryItems)}
            </div>
          </li>)
      }
    </SmartSpringGrid>;
  }

  _renderCategoriesItems(categoryItems) {
    return categoryItems.map(item =>
      <div className={styles.CoveredInClassExport_content_category_item}>
        <span className={styles.CoveredInClassExport_content_category_item_content}>
          {item.cicCategoryItemName}
        </span>
      </div>
    );
  }

  _renderFooter() {
    return <div className={styles.CoveredInClassExport_footer}>
      <div style={{ height: '120px', fontSize: '17px' }}>
        <div style={{ display: 'inline-block', marginTop: '25px' }}>
          <div>Do you want to know more about</div>
          <div>your child's results and homework?</div>
          <div style={{ marginTop: '20px' }}>Install EF Parents!</div>
        </div>
        <div className={styles.CoveredInClassExport_footer_qrcode} />
      </div>
      <hr />
      <span>© EF Education First 2016. All rights reserved.</span>
    </div>;
  }

  _renderHeader() {
    return <div className={styles.CoveredInClassExport_header}>
      <div className={styles.CoveredInClassExport_header_companyicon} />
      <h2>Covered in Class</h2>
      <div style={{
        display: 'inline-block',
        width: '50%',
        verticalAlign: 'top',
        fontSize: '17px',
        paddingLeft: '60px' }}>
        <div>Name Surname</div>
        <div>Teacher</div>
      </div>
      <div style={{ display: 'inline-block', width: '50%', fontSize: '15px' }}>
        <div style={{ marginBottom: '20px' }}>Course name and level</div>
        <div>Unit 2, session 5</div>
        <div>2016-03-04</div>
      </div>
    </div>;
  }

  _renderPageActivitiesPart(activities) {
    return <CardBlock className={styles.CoveredInClassExport_content_activity}>
      <div className={styles.CoveredInClassExport_content_activity_title}>Pages & Activties</div>
      <SmartSpringGrid component="ul"
          className={styles.CoveredInClassExport_content_grid}
          columns={3}
          columnWidth={230}
          itemHeight={60}
          gutterWidth={5}
          gutterHeight={5}
          layout={layout.simple}>
        {
          activities.map(activity =>
            <li style={{ width: '230px' }}>
              <Detailsboard boardTitle={activity.cicActivityName}
                  boardValue={this._activitiesString(activity.cicActivityItems)} />
            </li>)
        }
      </SmartSpringGrid>
    </CardBlock>;
  }

  _activitiesString(activities) {
    let activitiesStringResult = 'Activities: ';
    activities.map((activity, index) => {
      if (index !== 0) {
        activitiesStringResult += ', ';
      }
      activitiesStringResult += activity.cicActivityItemCode;
      return false;
    });
    return activitiesStringResult;
  }

  _renderActivityItems(activity) {
    return <div style={{ border: '1px solid #d0d0d0', padding: '5px' }}>
      <p>{activity.cicActivityName}</p>
      {activity.cicActivityItems.map(item =>
        <div style={{ paddingBottom: '5px', fontSize: '12px' }}>
          {item.cicActivityItemCode}
        </div>)}
    </div>;
  }

  render() {
    return <div className={styles.CoveredInClassExport}>
      <Button type={Button.Type.primary}
          className={styles.CoveredInClassExport_button}
          onClick={() => this._exportPage()} >
        Export
      </Button>
      {this._renderSessions()}
    </div>;
  }
}

CoveredInClassExport.propTypes = {
};

function mapStateToProps() {

  return {};
}

function mapDispatchToProps() {
  return {};
}

export default connect(mapStateToProps, mapDispatchToProps)(CoveredInClassExport);
