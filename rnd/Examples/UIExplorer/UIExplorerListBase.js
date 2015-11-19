/**
 * The examples provided by Facebook are for non-commercial testing and
 * evaluation purposes only.
 *
 * Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @flow
 */
'use strict';

var React = require('react-native-desktop');
var {
  //ListView,
  // PixelRatio,
  StyleSheet,
  Text,
  TextInput,
  TouchableHighlight,
  ScrollView,
  View,
} = React;
var createExamplePage = require('./createExamplePage');

// var ds = new ListView.DataSource({
//   rowHasChanged: (r1, r2) => r1 !== r2,
//   sectionHeaderHasChanged: (h1, h2) => h1 !== h2,
// });

class ListView extends React.Component {
    render() {
      var componentRows = this.props.dataSource.components.map((c, i) => this.props.renderRow(c, i));
      var apiRows = this.props.dataSource.apis.map((c, i) => this.props.renderRow(c, i));
      return (
        <ScrollView>
          {this.props.renderSectionHeader(null, 'Components:')}
          {componentRows}
          {this.props.renderSectionHeader(null, 'APIs:')}
          {apiRows}
        </ScrollView>
      );
    }
}

class UIExplorerListBase extends React.Component {
  constructor(props: any) {
    super(props);
    this.state = {
      // dataSource: ds.cloneWithRowsAndSections({
      //   components: [],
      //   apis: [],
      // }),
      dataSource: {
        components: [],
        apis: [],
      },
      searchText: this.props.searchText,
    };
  }

  componentDidMount(): void {
    this.search(this.state.searchText);
  }

  render() {
    var topView = this.props.renderAdditionalView &&
      this.props.renderAdditionalView(this.renderRow.bind(this), this.renderTextInput.bind(this));

    return (
      <View style={styles.listContainer}>
        {topView}
        <ListView
          style={styles.list}
          dataSource={this.state.dataSource}
          renderRow={this.renderRow.bind(this)}
          renderSectionHeader={this._renderSectionHeader}
          keyboardShouldPersistTaps={true}
          automaticallyAdjustContentInsets={false}
          keyboardDismissMode="on-drag"
        />
      </View>
    );
  }

  renderTextInput(searchTextInputStyle: any) {
    return (
      <View style={styles.searchRow}>
        <TextInput
          clearButtonMode="always"
          onChangeText={this.search.bind(this)}
          placeholder="Search..."
          //placeholderTextColor={'#ccc'}
          style={[styles.searchTextInput, searchTextInputStyle]}
          testID="explorer_search"
          value={this.state.searchText} />
      </View>
    );
  }

  _renderSectionHeader(data: any, section: string) {
    return (
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionHeaderTitle}>
          {section.toUpperCase()}
        </Text>
      </View>
    );
  }

  renderRow(example: any, i: number) {
    var selected = this.state.selected === example.title ? styles.selectedRow : {};
    var hovered = this.state.hovered === example.title ? styles.hoveredRow : {};
    return (
      <TouchableHighlight onPress={() => this.onPressRow(example)}
      onMouseEnter={() => this.setState({hovered: example.title})}
    //  onMouseLeave={() => this.setState({hovered: -1})}
      key={i} style={[styles.row, hovered, selected]}>
        <View>
          <Text style={styles.rowTitleText}>
            {example.title}
          </Text>
          <Text style={styles.rowDetailText}>
            {example.description}
          </Text>
        </View>
      </TouchableHighlight>
    );
  }

  search(text: mixed): void {
    this.props.search && this.props.search(text);

    var regex = new RegExp(text, 'i');
    var filter = (component) => regex.test(component.title);

    this.setState({
      // dataSource: ds.cloneWithRowsAndSections({
      //   components: this.props.components.filter(filter),
      //   apis: this.props.apis.filter(filter),
      // }),
      dataSource: {
        components: this.props.components.filter(filter),
        apis: this.props.apis.filter(filter),
      },
      searchText: text,
    });
  }

  onPressRow(example: any): void {
    this.setState({selected: example.title});
    this.props.onPressRow && this.props.onPressRow(example);
  }

  static makeRenderable(example: any): ReactClass<any, any, any> {
    return example.examples ?
      createExamplePage(null, example) :
      example;
  }
}

var styles = StyleSheet.create({
  listContainer: {
    flex: 1,
  },
  list: {
    backgroundColor: '#eeeeee',
  },
  sectionHeader: {
    padding: 5,
  },
  group: {
    backgroundColor: 'white',
  },
  sectionHeaderTitle: {
    fontWeight: '500',
    fontSize: 11,
    color: 'white'
  },
  row: {
    backgroundColor: 'white',
    justifyContent: 'center',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderBottomColor: 'white'
  },
  separator: {
    height: 1,//PixelRatio.get(),
    backgroundColor: '#bbbbbb',
    marginLeft: 15,
  },
  rowTitleText: {
    fontSize: 15,
    fontWeight: '500',
  },
  rowDetailText: {
    fontSize: 12,
    color: '#888888',
    lineHeight: 20,
  },
  searchRow: {
    backgroundColor: '#eee',
    padding: 5,
    borderColor: '#ccc',
    borderRadius: 3,
    borderWidth: 1,
  },
  searchTextInput: {
    fontWeight: '200',
    fontSize: 12,
    //textAlign: 'center'
  },
  selectedRow: {
    backgroundColor: '#fffd7e'
  },
  hoveredRow: {
    backgroundColor: '#ddd'
  }
});

module.exports = UIExplorerListBase;
